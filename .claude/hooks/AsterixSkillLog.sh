#!/bin/bash
# Claude Code Hook - Send skill use events to local API endpoint.
# Wired to PreToolUse with matcher "Skill". Sends one event per skill
# invocation; the event manager handles its own queueing/dedup. Local
# queue file is only used to buffer when the endpoint is unreachable
# (off-VPN), draining on the next successful send.

LOCAL_API_URL="https://athena.webmdhelios.com/asterix-metrics/events"
QUEUE_FILE="$HOME/.athena-skill-queue.jsonl"
MAX_QUEUE=500
# Cap on drain iterations per invocation — defense in depth so a bug
# in the queue-trim step can never spin forever.
MAX_DRAIN_PER_RUN=50

command -v jq >/dev/null 2>&1 || exit 0

# Read stdin (hook event JSON) with a hard time bound so a misbehaving
# harness that doesn't close the pipe can't pin this script forever.
# 1s is plenty — the harness writes the JSON in a single syscall.
HOOK_INPUT=""
if command -v timeout >/dev/null 2>&1; then
    HOOK_INPUT=$(timeout 1 cat 2>/dev/null || true)
else
    HOOK_INPUT=$(cat 2>/dev/null || true)
fi
[ -z "$HOOK_INPUT" ] && exit 0

SKILL_NAME=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[ -z "$SKILL_NAME" ] && exit 0

# Drop plugin-namespaced skills (form: "plugin:skill") — out of scope.
case "$SKILL_NAME" in
    *:*) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
fi

# Respect XDG if Claude used it, fall back to ~/.claude (user-level only;
# project-level config always lives under <project>/.claude).
if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/claude" ]; then
    CLAUDE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
else
    CLAUDE_DIR="$HOME/.claude"
fi

# Project-level shadows user-level (matches Claude Code skill resolution).
# If the skill doesn't resolve under user/project paths, it's out of scope
# (plugin skill, marketplace skill, or unknown) — drop the use event.
SKILL_FILE=""
if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/.claude/skills/$SKILL_NAME/SKILL.md" ]; then
    SKILL_FILE="$PROJECT_DIR/.claude/skills/$SKILL_NAME/SKILL.md"
elif [ -f "$CLAUDE_DIR/skills/$SKILL_NAME/SKILL.md" ]; then
    SKILL_FILE="$CLAUDE_DIR/skills/$SKILL_NAME/SKILL.md"
fi
[ -z "$SKILL_FILE" ] && exit 0

SKILL_DESC=$(awk '
    /^---[[:space:]]*$/ { count++; if (count == 2) exit; next }
    count == 1 && /^description:/ {
        sub(/^description:[[:space:]]*/, "")
        sub(/^"/, "")
        sub(/"[[:space:]]*$/, "")
        sub(/[[:space:]]+$/, "")
        print
        exit
    }
' "$SKILL_FILE")

# --- Determine user email (same lookup order as SendAsterixMetrics.sh) ---
# Locate .claude.json: normally ~/.claude.json, but an XDG install can place it
# inside the config dir — try both, first hit wins.
CLAUDE_JSON=""
for _candidate in "$HOME/.claude.json" "${XDG_CONFIG_HOME:-$HOME/.config}/claude/.claude.json"; do
    if [ -f "$_candidate" ]; then
        CLAUDE_JSON="$_candidate"
        break
    fi
done

USER_EMAIL=""
if [ -n "$CLAUDE_JSON" ]; then
    USER_EMAIL=$(grep -o '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$CLAUDE_JSON" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi
if [ -z "$USER_EMAIL" ] && [ -f "$HOME/.athena-config/athena-config.json" ]; then
    USER_EMAIL=$(grep -o '"user-email"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.athena-config/athena-config.json" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

PAYLOAD=$(jq -nc \
    --arg name "$SKILL_NAME" \
    --arg desc "$SKILL_DESC" \
    --arg email "$USER_EMAIL" \
    '{event_type: "skill-use", data: {user: $email, skill_name: $name, skill_desc: $desc}}')

# --- Step 1: Try to send current event directly ---
if curl -sf -o /dev/null --connect-timeout 3 --max-time 5 \
    -X POST "$LOCAL_API_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD"; then

    # --- Step 2: Success — drain any queued items in background ---
    # Trim the head with `tail -n +2 > tmp && mv` rather than `sed -i '1d'`:
    # BSD sed (macOS) requires `-i ''` and would treat '1d' as the backup
    # suffix, silently corrupting the queue file. tail+mv is portable.
    if [ -s "$QUEUE_FILE" ]; then
        (
            iter=0
            while [ -s "$QUEUE_FILE" ] && [ "$iter" -lt "$MAX_DRAIN_PER_RUN" ]; do
                iter=$((iter + 1))
                line=$(head -n 1 "$QUEUE_FILE")
                if curl -sf -o /dev/null --connect-timeout 3 --max-time 5 \
                    -X POST "$LOCAL_API_URL" \
                    -H "Content-Type: application/json" \
                    -d "$line"; then
                    if tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp" 2>/dev/null; then
                        mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
                    else
                        break
                    fi
                else
                    break
                fi
            done
        ) >/dev/null 2>&1 < /dev/null &
        disown
    fi

else
    # --- Step 3: Failed — queue current payload for later retry ---
    QUEUE_SIZE=$(wc -l < "$QUEUE_FILE" 2>/dev/null || echo 0)
    # wc on macOS prints leading whitespace; strip non-digits.
    QUEUE_SIZE=${QUEUE_SIZE//[^0-9]/}
    : "${QUEUE_SIZE:=0}"
    if [ "$QUEUE_SIZE" -lt "$MAX_QUEUE" ]; then
        echo "$PAYLOAD" >> "$QUEUE_FILE"
    fi
fi

exit 0

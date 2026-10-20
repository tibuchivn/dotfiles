#!/bin/bash
# Claude Code Hook - Send metrics to local API endpoint
# Requires only curl (standard on most systems)

VERSION="5.1.0"

# Local API endpoint
LOCAL_API_URL="https://athena.corp.example.com/claude-code/metrics"

# Queue file for off-VPN buffering
QUEUE_FILE="$HOME/.athena-metrics-queue.jsonl"
MAX_QUEUE=500
# Cap on drain iterations per invocation — defense in depth so a bug
# in the queue-trim step can never spin forever.
MAX_DRAIN_PER_RUN=50

# Read stdin (hook event JSON) with a hard time bound so a misbehaving
# harness that doesn't close the pipe can't pin this script forever.
# 1s is plenty — the harness writes the JSON in a single syscall.
HOOK_INPUT=""
if command -v timeout >/dev/null 2>&1; then
    HOOK_INPUT=$(timeout 1 cat 2>/dev/null || true)
else
    HOOK_INPUT=$(cat 2>/dev/null || true)
fi

# Locate Claude's config file (.claude.json). Normally ~/.claude.json, but an
# XDG install can place it inside the config dir — try both, first hit wins.
CLAUDE_JSON=""
for _candidate in "$HOME/.claude.json" "${XDG_CONFIG_HOME:-$HOME/.config}/claude/.claude.json"; do
    if [ -f "$_candidate" ]; then
        CLAUDE_JSON="$_candidate"
        break
    fi
done

# --- Determine model ---
MODEL=""

if [ -n "$HOOK_INPUT" ] && [ -n "$CLAUDE_JSON" ]; then
    TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    TRANSCRIPT_DIR=$(basename "$(dirname "$TRANSCRIPT_PATH")")

    if [ -n "$TRANSCRIPT_DIR" ] && command -v jq &>/dev/null; then
        MODEL=$(jq -r --arg dir "$TRANSCRIPT_DIR" '
            to_entries[]
            | select((.key | gsub("/"; "-")) == $dir)
            | .value.lastModelUsage
            | to_entries
            | max_by(.value.costUSD)
            | .key
        ' "$CLAUDE_JSON" 2>/dev/null | head -1)
        [ "$MODEL" = "null" ] && MODEL=""
    fi
fi

# Fallback
if [ -z "$MODEL" ]; then
    MODEL="claude-sonnet-4-6"
fi

# --- Determine user email ---
USER_EMAIL=""

# 1. Try .claude.json -> oauthAccount.emailAddress
if [ -n "$CLAUDE_JSON" ]; then
    USER_EMAIL=$(grep -o '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$CLAUDE_JSON" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# 2. Try ~/.athena-config/athena-config.json -> user-email
if [ -z "$USER_EMAIL" ] && [ -f "$HOME/.athena-config/athena-config.json" ]; then
    USER_EMAIL=$(grep -o '"user-email"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.athena-config/athena-config.json" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# --- Build payload ---
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
PAYLOAD="{\"user_id\":\"${USER_EMAIL}\",\"model\":\"${MODEL}\",\"time\":\"${TIMESTAMP}\"}"

# --- Step 1: Try to send current event directly ---
if curl -sf -o /dev/null --connect-timeout 3 --max-time 5 \
    -X POST "$LOCAL_API_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD"; then

    # --- Step 2: Success — drain any queued items in background ---
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

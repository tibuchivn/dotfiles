#!/bin/bash
# AsterixStoryLog.sh - Add entry to asterix_story_log.json if not already modified in current git changes

VERSION="5.1.0"

# Read stdin (hook event JSON)
HOOK_INPUT=$(cat 2>/dev/null || true)

# Get git repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
    exit 0
fi

# If asterix_story_log.json is already in git changes, skip
if git -C "$REPO_ROOT" status --short 2>/dev/null | grep -q "asterix_story_log.json"; then
    exit 0
fi

# --- Determine model ---
MODEL="claude-sonnet-4-6"

TICKET_ID="ATHENA-3342"

# --- Timestamp (portable across BSD/GNU date) ---
# GNU date supports the %3N width modifier for milliseconds. BSD date
# (macOS) does not — it emits the literal string "3N", producing
# malformed timestamps like "...55.3NZ". Probe %3N directly: only the
# all-digits result means we have GNU date.
if [[ "$(date -u +%3N 2>/dev/null)" =~ ^[0-9]+$ ]]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
elif command -v python3 >/dev/null 2>&1; then
    TIMESTAMP=$(python3 -c 'from datetime import datetime,timezone;n=datetime.now(timezone.utc);print(n.strftime("%Y-%m-%dT%H:%M:%S.")+f"{n.microsecond//1000:03d}Z")')
else
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
fi

# --- JSON file path ---
JSON_FILE="$REPO_ROOT/asterix_story_log.json"

# --- Add entry using jq ---
if [ ! -f "$JSON_FILE" ]; then
    echo '{"log":[]}' > "$JSON_FILE"
fi

jq --arg ticket "$TICKET_ID" \
   --arg model "claude-code/$MODEL" \
   --arg ts "$TIMESTAMP" \
   '.log += [{
     "ticket_id": $ticket,
     "description": "-",
     "llm_version": $model,
     "last_updated": $ts,
     "mode": "claude"
   }]' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"

git -C "$REPO_ROOT" add asterix_story_log.json 2>/dev/null

exit 0

#!/bin/bash
HOOKS_DIR=/Users/tung.tram/.claude/hooks
INSTALL_DIR=''
# CheckVersion.sh - Check for hook updates on session start

VERSION_FILE="$HOOKS_DIR/.version"
API_URL="https://athena.webmdhelios.com/api/install/update-script"

# Read stdin (hook event JSON)
HOOK_INPUT=$(cat 2>/dev/null || true)

# Ensure .version exists
if [ ! -f "$VERSION_FILE" ]; then
    echo '{"version":"5.1.0","last_check":""}' > "$VERSION_FILE"
fi

# Read version and last_check
CURRENT_VERSION=$(jq -r '.version // "5.1.0"' "$VERSION_FILE" 2>/dev/null || echo "5.1.0")
LAST_CHECK=$(jq -r '.last_check // ""' "$VERSION_FILE" 2>/dev/null || echo "")

# Skip API call if last_check was within the last 24 hours
if [ -n "$LAST_CHECK" ] && [ "$LAST_CHECK" != "null" ]; then
    # Try GNU date (Linux), fall back to BSD date (macOS)
    LAST_CHECK_TS=$(date -d "$LAST_CHECK" +%s 2>/dev/null)
    if [ -z "$LAST_CHECK_TS" ]; then
        LAST_CHECK_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${LAST_CHECK%.*}" +%s 2>/dev/null)
    fi
    if [ -n "$LAST_CHECK_TS" ]; then
        NOW=$(date -u +%s)
        DIFF=$((NOW - LAST_CHECK_TS))
        if [ "$DIFF" -lt 86400 ]; then
            echo "Happy coding!"
            exit 0
        fi
    fi
fi

# Update last_check every time the check runs (regardless of API result)
NEW_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
jq --arg ts "$NEW_TIMESTAMP" '.last_check = $ts' "$VERSION_FILE" \
    > "${VERSION_FILE}.tmp" 2>/dev/null \
    && mv "${VERSION_FILE}.tmp" "$VERSION_FILE" 2>/dev/null

# Call API with current version to check for updates
RESPONSE=$(curl -sf --connect-timeout 5 --max-time 10 \
    "${API_URL}?version=${CURRENT_VERSION}&provider=claude" 2>/dev/null || true)

if [ -n "$RESPONSE" ]; then
    # Execute the returned setup script (full update or happy-coding echo).
    # Forward --install-dir so a custom install updates in place instead of
    # falling back to the default ~/.claude/hooks.
    local tmp_update
    tmp_update="$(mktemp "${TMPDIR:-/tmp}/asterix-update-XXXXXX.sh")"
    printf '%s' "$RESPONSE" > "$tmp_update"
    if [ -n "$INSTALL_DIR" ]; then
        bash "$tmp_update" --install-dir "$INSTALL_DIR"
    else
        bash "$tmp_update"
    fi
    rm -f "$tmp_update"
else
    echo "Happy coding!"
fi

exit 0

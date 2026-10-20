#!/bin/bash
# SpendCheck.sh — post-response spend monitor (wired to Stop event).
# Asks the Athena cc-coach API for month-to-date spend; the API returns
# `cap_warning` (bool) and `user_message` (string). When cap_warning is true the
# hook surfaces user_message to the developer. Cap thresholds and the message
# text live in the API, not here. Throttled to at most twice per day (AM / PM
# half). Needs only curl + jq.

SPEND_API_BASE="https://athena.corp.example.com/api/claude-code/coach/spend"

CLAUDE_DIR_CHECK=""
if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/claude" ]; then
    CLAUDE_DIR_CHECK="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
else
    CLAUDE_DIR_CHECK="$HOME/.claude"
fi

STAMP_FILE="$CLAUDE_DIR_CHECK/hooks/.spend_check_stamp"

# Drain stdin (Stop event JSON) so the pipe never blocks; we don't use it.
if command -v timeout >/dev/null 2>&1; then
    timeout 1 cat >/dev/null 2>&1 || true
else
    cat >/dev/null 2>&1 || true
fi

# --- Throttle: run at most twice per day (AM / PM half) ---
HALF=$([ "$(date -u +%H)" -lt 12 ] && echo AM || echo PM)
STAMP_KEY="$(date -u +%Y-%m-%d)-$HALF"
if [ -f "$STAMP_FILE" ] && [ "$(cat "$STAMP_FILE" 2>/dev/null)" = "$STAMP_KEY" ]; then
    exit 0
fi

# --- Determine user email (same lookup order as SendMetrics.sh) ---
USER_EMAIL=""
if [ -f "$HOME/.claude.json" ]; then
    USER_EMAIL=$(grep -o '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude.json" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi
if [ -z "$USER_EMAIL" ] && [ -f "$HOME/.athena-config/athena-config.json" ]; then
    USER_EMAIL=$(grep -o '"user-email"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.athena-config/athena-config.json" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# No email → can't query; record the attempt and exit quietly.
if [ -z "$USER_EMAIL" ]; then
    echo "$STAMP_KEY" > "$STAMP_FILE" 2>/dev/null
    exit 0
fi

# --- Fetch authoritative spend from the API (current month) ---
RESPONSE=$(curl -sf --connect-timeout 3 --max-time 5 \
    -H "Accept: application/json" \
    "${SPEND_API_BASE}?email=${USER_EMAIL}" 2>/dev/null || true)

# Stamp regardless of outcome so a flaky/offline API doesn't retry every response.
echo "$STAMP_KEY" > "$STAMP_FILE" 2>/dev/null

[ -z "$RESPONSE" ] && exit 0

# jq is required to read the API verdict; without it we can't proceed.
command -v jq >/dev/null 2>&1 || exit 0

# The API owns the cap logic and the message text. Only warn when it says so.
CAP_WARNING=$(echo "$RESPONSE" | jq -r '.cap_warning // false' 2>/dev/null)
[ "$CAP_WARNING" = "true" ] || exit 0

USER_MESSAGE=$(echo "$RESPONSE" | jq -r '.user_message // empty' 2>/dev/null)
[ -z "$USER_MESSAGE" ] && exit 0

# --- Surface the warning to the user. A Stop-hook's plain stdout only appears in
# --- transcript mode (Ctrl-R), so emit a JSON systemMessage, which Claude Code
# --- renders inline to the user. ---
jq -n --arg m "$USER_MESSAGE" '{systemMessage: $m}'

exit 0

#!/bin/bash
# CheckGittrace.sh - ensure asterix-gittrace is installed and up to date, unless
# this account is blocked by the EU/GDPR region policy.

API_BASE_INSTALL="https://athena.webmdhelios.com/asterix-gittrace/install.sh"
API_BASE_UPDATE="https://athena.webmdhelios.com/api/install/update-gittrace"
# Written by the script the API serves to a blocked user. It lives outside every
# script the API serves, so re-downloading an installer cannot clear it.
STATE_FILE="$HOME/.asterix-gittrace/.version"

# The binary lives in ~/.asterix-gittrace/bin, which is not always on PATH in a
# non-login shell, so add it before probing.
export PATH="$HOME/.asterix-gittrace/bin:$HOME/.local/bin:$PATH"

# Drain stdin (hook event JSON); we don't use it.
cat >/dev/null 2>&1 || true

# --- Resolve the logged-in email (same lookup order as SendAsterixMetrics.sh) ---
USER_EMAIL=""
CLAUDE_JSON="$HOME/.claude.json"
if [ -f "$CLAUDE_JSON" ]; then
    USER_EMAIL=$(grep -o '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$CLAUDE_JSON" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi
if [ -z "$USER_EMAIL" ] && [ -f "$HOME/.athena-config/athena-config.json" ]; then
    USER_EMAIL=$(grep -o '"user-email"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.athena-config/athena-config.json" | head -1 | sed 's/.*"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# --- Blocked accounts stop here, before any network call --------------------
# IS_GDPR is only ever written by the script the API serves to a blocked user, so
# its presence means the server has already decided. GDPR_EMAIL is compared as
# well so that logging in as a different account is re-checked rather than
# inheriting the previous account's verdict.
IS_GDPR=""
GDPR_EMAIL=""
if [ -f "$STATE_FILE" ]; then
    . "$STATE_FILE" 2>/dev/null || true
fi
if [ "$IS_GDPR" = "true" ] && [ "$GDPR_EMAIL" = "$USER_EMAIL" ]; then
    exit 0
fi

# Without an email the API cannot place the user, so there is nothing to ask for.
if [ -z "$USER_EMAIL" ]; then
    exit 0
fi

# Percent-encode for the query string. jq's @uri is used when available (the
# setup script installs jq); the fallback encodes byte by byte under LC_ALL=C.
urlencode() {
    if command -v jq >/dev/null 2>&1; then
        jq -rn --arg v "$1" '$v|@uri' 2>/dev/null && return 0
    fi
    local LC_ALL=C
    local str="$1" out="" i c
    for (( i = 0; i < ${#str}; i++ )); do
        c="${str:i:1}"
        case "$c" in
            [A-Za-z0-9.~_-]) out="$out$c" ;;
            *) out="$out$(printf '%%%02X' "'$c")" ;;
        esac
    done
    printf '%s' "$out"
}

EMAIL_ENC=$(urlencode "$USER_EMAIL")

VERSION=$(asterix-gittrace --version 2>/dev/null | awk '{print $NF}')

# The installer resolves the platform (macos x86_64/arm64 vs linux) itself, so
# only the version is reported here. The API answers with the installer, or with
# a script that records a GDPR block and installs nothing, or with 204 for
# "nothing to do" -- so piping whatever comes back is all that is needed.
if [ -n "$VERSION" ]; then
    curl -sf --connect-timeout 5 --max-time 10 \
        "${API_BASE_UPDATE}?version=${VERSION}&email=${EMAIL_ENC}" 2>/dev/null | bash
else
    curl -sf --connect-timeout 5 --max-time 30 \
        "${API_BASE_INSTALL}?email=${EMAIL_ENC}" 2>/dev/null | bash
fi

exit 0

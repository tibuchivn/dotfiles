#!/bin/bash
# Watches the fvpn/openfortivpn tunnel and notifies only when it matters.
#
# The root helper records what the user asked for in /var/log/fvpn-intent
# ("up <gw> <epoch> <deadline>" or "down - <epoch>"), so:
#   * a deliberate `fvpn down` stays silent,
#   * a fresh login/boot with no VPN requested stays silent,
#   * an `up` that is still waiting for the FortiToken push / typed OTP stays
#     silent until its deadline passes (the user is still authenticating),
#   * only "up was requested and the deadline passed but the tunnel is not
#     healthy" raises a banner, at most once per request (not every minute).
# It never reconnects: retrying blindly is how AD accounts get locked out.
# Started by the launchd agent ai.fvpn.watch every 60s (see ai.fvpn.watch.plist).
set -uo pipefail
PATH=/usr/bin:/bin:/usr/sbin:/sbin

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# tenant values (DNS_PROBE, ...) - optional, gitignored
if [ -r "$SCRIPT_DIR/fvpn.local.sh" ]; then . "$SCRIPT_DIR/fvpn.local.sh"; fi
DNS_PROBE="${DNS_PROBE:-}"

STATE_DIR="$HOME/Library/Application Support/fvpn-watch"
WSTATE="${FVPN_WSTATE:-$STATE_DIR/state}"
LOG="${FVPN_WATCH_LOG:-$HOME/Library/Logs/fvpn-watch.log}"
INTENT="${FVPN_INTENT:-/var/log/fvpn-intent}"    # written by /usr/local/sbin/fvpn-root
UP_GRACE="${UP_GRACE:-180}"    # fallback for an intent file without a deadline field

/bin/mkdir -p "$STATE_DIR"
log() { { printf '%s %s\n' "$(/bin/date '+%F %T')" "$*" >> "$LOG"; } 2>/dev/null || true; }

notify() {  # $1 title, $2 message
  if [ -n "${FVPN_FAKE_STATE:-}" ]; then   # offline tests must not raise real banners
    log "TEST-notify: $1 - $2"
    return 0
  fi
  /usr/bin/osascript >/dev/null 2>&1 <<EOF
display notification "$2" with title "$1" sound name "Basso"
EOF
}

# --- current tunnel health (FVPN_FAKE_STATE exists so this can be tested offline)
cur="down"
if [ -n "${FVPN_FAKE_STATE:-}" ]; then
  cur="$FVPN_FAKE_STATE"
elif /sbin/ifconfig ppp0 2>/dev/null | /usr/bin/grep -q 'inet '; then
  if [ -n "$DNS_PROBE" ] && ! /sbin/ping -c 2 -W 2000 -q "$DNS_PROBE" >/dev/null 2>&1; then
    cur=unreachable
  else
    cur=up
  fi
fi

# --- what the user last asked for
intent_action=""
intent_ts=""
intent_deadline=""
if [ -r "$INTENT" ]; then
  read -r intent_action _gw intent_ts intent_deadline < "$INTENT" 2>/dev/null || true
fi

w_ts=""
w_notified=0
if [ -r "$WSTATE" ]; then
  read -r w_ts w_notified < "$WSTATE" 2>/dev/null || true
fi

case "$intent_action" in
  up)
    if [ "$cur" = up ]; then
      printf '%s 0\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true   # re-arm for a later drop
      log "ok: tunnel up (request $intent_ts)"
    else
      # Still inside the approval window (FortiToken push ringing, or the user typing
      # an OTP): the tunnel is *supposed* to be down. Say nothing and wait.
      _now=$(/bin/date +%s)
      case "${intent_deadline:-}" in
        ''|*[!0-9]*) _deadline=$(( ${intent_ts:-0} + UP_GRACE )) ;;
        *) _deadline=$intent_deadline ;;
      esac
      if [ "$_now" -lt "$_deadline" ]; then
        log "up pending: $(( _deadline - _now ))s left to approve, staying silent (state $cur)"
        exit 0
      fi
      [ "${w_ts:-}" = "$intent_ts" ] || w_notified=0
      if [ "${w_notified:-0}" = 0 ]; then
        if [ "$cur" = unreachable ]; then
          notify "VPN unreachable" "ppp0 is up but $DNS_PROBE does not answer"
        else
          notify "VPN not connected" "fvpn up was requested but the tunnel never came up (ppp0 missing)"
        fi
        printf '%s 1\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
        log "notified: $cur (request $intent_ts, deadline $_deadline)"
      else
        log "already notified for request $intent_ts ($cur)"
      fi
    fi
    ;;
  down)
    printf '%s 0\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
    log "request down: staying silent ($cur)"
    ;;
  *)
    log "no request recorded yet, nothing to watch (state $cur)"
    ;;
esac

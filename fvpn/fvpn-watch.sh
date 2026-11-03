#!/bin/bash
# Watches the fvpn/openfortivpn tunnel and notifies only when it matters.
#
# The root helper records what the user asked for in /var/log/fvpn-intent
# ("up <gw> <epoch> <deadline> [ok]" or "down - <epoch>"), so:
#   * a deliberate `fvpn down` stays silent,
#   * a fresh login/boot with no VPN requested stays silent,
#   * an `up` that is still waiting for the FortiToken push / typed OTP stays
#     silent until its deadline passes (the user is still authenticating),
#   * an `up` that never produced a tunnel is silent too - `fvpn up` already
#     printed the error, and this request did not drop anything. Set
#     UP_FAIL_NOTIFY=1 in fvpn.local.sh to get a banner for it anyway,
#   * a tunnel that did come up and then went away raises one banner ("VPN
#     dropped"), at most once per request.
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
UP_GRACE="${UP_GRACE:-180}"          # fallback when the intent has no deadline field
UP_FAIL_NOTIFY="${UP_FAIL_NOTIFY:-0}" # 1 = also banner an `up` that never connected

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
intent_result=""
if [ -r "$INTENT" ]; then
  read -r intent_action _gw intent_ts intent_deadline intent_result < "$INTENT" 2>/dev/null || true
fi

w_ts=""
w_notified=0
w_seen_up=0
if [ -r "$WSTATE" ]; then
  read -r w_ts w_notified w_seen_up < "$WSTATE" 2>/dev/null || true
fi
[ "${w_ts:-}" = "${intent_ts:-}" ] || { w_notified=0; w_seen_up=0; }   # a different request
[ "${intent_result:-}" = ok ] && w_seen_up=1   # the helper confirmed it really connected

case "$intent_action" in
  up)
    if [ "$cur" = up ]; then
      printf '%s 0 1\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true   # re-arm for a later drop
      log "ok: tunnel up (request $intent_ts)"
    elif [ "$cur" = unreachable ]; then
      # ppp0 exists, so the tunnel did come up and has since gone bad
      if [ "${w_notified:-0}" = 0 ]; then
        notify "VPN unreachable" "ppp0 is up but $DNS_PROBE does not answer"
        printf '%s 1 1\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
        log "notified: unreachable (request $intent_ts)"
      else
        log "already notified for request $intent_ts (unreachable)"
      fi
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
      if [ "${w_seen_up:-0}" = 1 ]; then
        # it connected and then vanished: this is the drop the user asked about
        if [ "${w_notified:-0}" = 0 ]; then
          notify "VPN dropped" "the tunnel is gone (ppp0 missing); run fvpn up again"
          printf '%s 1 1\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
          log "notified: dropped (request $intent_ts)"
        else
          log "already notified for request $intent_ts (dropped)"
        fi
      else
        # never connected: `fvpn up` already printed why, and nothing was lost.
        if [ "${UP_FAIL_NOTIFY:-0}" = 1 ] && [ "${w_notified:-0}" = 0 ]; then
          notify "VPN not connected" "fvpn up was requested but the tunnel never came up (ppp0 missing)"
          printf '%s 1 0\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
          log "notified: never connected (request $intent_ts)"
        else
          printf '%s 1 0\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
          log "up ended without a tunnel, nothing to report (request $intent_ts)"
        fi
      fi
    fi
    ;;
  down)
    printf '%s 0 0\n' "$intent_ts" > "$WSTATE" 2>/dev/null || true
    log "request down: staying silent ($cur)"
    ;;
  *)
    log "no request recorded yet, nothing to watch (state $cur)"
    ;;
esac

#!/bin/bash
# Offline regression tests for fvpn-watch.sh.
#
# No real tunnel and no real banners: the watcher honours FVPN_FAKE_STATE,
# FVPN_INTENT, FVPN_WSTATE and FVPN_WATCH_LOG, and suppresses osascript while
# FVPN_FAKE_STATE is set. Run it after touching the watcher:
#
#   bash fvpn/test-fvpn-watch.sh
#
set -u
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
W="$HERE/fvpn-watch.sh"
T=$(mktemp -d "${TMPDIR:-/tmp}/fvpn-watch-test.XXXXXX")
pass=0; fail=0
now=$(/bin/date +%s)

run() {  # $1 label, $2 expected substring in log, $3 fake state, $4 intent line, [$5 pre-existing state]
  local label="$1" want="$2" state="$3" intent="$4" pre="${5:-}"
  rm -f "$T/log" "$T/state"
  printf '%s\n' "$intent" > "$T/intent"
  [ -n "$pre" ] && printf '%s\n' "$pre" > "$T/state"
  FVPN_FAKE_STATE="$state" FVPN_INTENT="$T/intent" FVPN_WSTATE="$T/state" \
    FVPN_WATCH_LOG="$T/log" /bin/bash "$W"
  local rc=$? out; out=$(cat "$T/log" 2>/dev/null)
  if [ "$rc" -ne 0 ]; then
    printf '   FAIL %-46s exit=%s\n' "$label" "$rc"; fail=$((fail+1)); return
  fi
  if printf '%s' "$out" | /usr/bin/grep -q -- "$want"; then
    printf '   PASS %-46s %s\n' "$label" "$(printf '%s' "$out" | head -1 | cut -c21-)"
    pass=$((pass+1))
  else
    printf '   FAIL %-46s got: %s\n' "$label" "$(printf '%s' "$out" | head -1)"
    fail=$((fail+1))
  fi
}

echo "=== approval window is silent ==="
run "up, deadline +120s, tunnel down"      "up pending"        down "up asia1 $now $((now+120))"
run "up, deadline +15s (about to expire)"  "up pending"        down "up asia1 $now $((now+15))"

echo "=== a real failure still notifies ==="
run "up, deadline 60s ago, tunnel down"    "TEST-notify: VPN not connected" down "up asia1 $((now-200)) $((now-60))"
run "up, deadline passed, dead tunnel"     "TEST-notify: VPN unreachable"   unreachable "up asia1 $((now-200)) $((now-60))"
run "same request twice -> once only"      "already notified"  down "up asia1 $((now-200)) $((now-60))" "$((now-200)) 1"

echo "=== intent without a deadline falls back to UP_GRACE=180 ==="
run "legacy intent, 30s old"               "up pending"        down "up asia1 $((now-30))"
run "legacy intent, 300s old"              "TEST-notify: VPN not connected" down "up asia1 $((now-300))"

echo "=== unchanged behaviour ==="
run "tunnel up after request"              "ok: tunnel up"     up   "up asia1 $((now-40)) $((now+10))"
run "deliberate down"                      "request down"      down "down - $now"
run "no request recorded"                  "no request recorded" down ""

echo
echo "   passed=$pass failed=$fail"
rm -rf "$T"
[ "$fail" -eq 0 ]

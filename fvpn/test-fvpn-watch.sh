#!/bin/bash
# Offline regression tests for fvpn-watch.sh.
#
# No real tunnel and no real banners: the watcher honours FVPN_FAKE_STATE,
# FVPN_INTENT, FVPN_WSTATE, FVPN_WATCH_LOG and UP_FAIL_NOTIFY, and it logs
# instead of calling osascript while FVPN_FAKE_STATE is set.
#
#   bash fvpn/test-fvpn-watch.sh
#
set -u
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
W="$HERE/fvpn-watch.sh"
T=$(mktemp -d "${TMPDIR:-/tmp}/fvpn-watch-test.XXXXXX")
pass=0; fail=0
now=$(/bin/date +%s)

run() {  # label, expected log substring, fake state, intent line, [state line], [extra env]
  local label="$1" want="$2" state="$3" intent="$4" pre="${5:-}" extra="${6:-}"
  rm -f "$T/log" "$T/state" "$T/deadcount"
  printf '%s\n' "$intent" > "$T/intent"
  [ -n "$pre" ] && printf '%s\n' "$pre" > "$T/state"
  env $extra FVPN_FAKE_STATE="$state" FVPN_INTENT="$T/intent" FVPN_WSTATE="$T/state" \
    FVPN_WATCH_LOG="$T/log" /bin/bash "$W"
  local rc=$? out; out=$(cat "$T/log" 2>/dev/null)
  if [ "$rc" -ne 0 ]; then
    printf '   FAIL %-48s exit=%s\n' "$label" "$rc"; fail=$((fail+1)); return
  fi
  if printf '%s' "$out" | /usr/bin/grep -q -- "$want"; then
    printf '   PASS %-48s %s\n' "$label" "$(printf '%s' "$out" | head -1 | cut -c21-)"
    pass=$((pass+1))
  else
    printf '   FAIL %-48s got: %s\n' "$label" "$(printf '%s' "$out" | head -1)"
    fail=$((fail+1))
  fi
}

run_times() {  # label, expected log substring, state, intent, ticks, [extra env], [must NOT contain]
  local label="$1" want="$2" state="$3" intent="$4" n="$5" extra="${6:-}" notwant="${7:-}"
  rm -f "$T/log" "$T/state" "$T/deadcount"
  printf '%s\n' "$intent" > "$T/intent"
  local i=0 out=""
  while [ "$i" -lt "$n" ]; do
    i=$((i+1)); rm -f "$T/log"
    env $extra FVPN_FAKE_STATE="$state" FVPN_INTENT="$T/intent" FVPN_WSTATE="$T/state" \
      FVPN_WATCH_LOG="$T/log" /bin/bash "$W"
    out=$(cat "$T/log" 2>/dev/null)
  done
  if ! printf '%s' "$out" | /usr/bin/grep -q -- "$want"; then
    printf '   FAIL %-48s got: %s\n' "$label" "$(printf '%s' "$out" | head -1)"
    fail=$((fail+1)); return
  fi
  if [ -n "$notwant" ] && printf '%s' "$out" | /usr/bin/grep -q -- "$notwant"; then
    printf '   FAIL %-48s unexpected: %s\n' "$label" "$(printf '%s' "$out" | /usr/bin/grep -- "$notwant" | head -1)"
    fail=$((fail+1)); return
  fi
  printf '   PASS %-48s %s\n' "$label" "$(printf '%s' "$out" | head -1 | cut -c21-)"
  pass=$((pass+1))
}

echo "=== the reported bug: push still ringing, tunnel still down ==="
run "up, deadline +120s, tunnel down"        "up pending"                     down "up asia1 $now $((now+120))"
run "up, deadline +15s (about to expire)"    "up pending"                     down "up asia1 $now $((now+15))"

echo "=== attempt ended without a tunnel: silent, no fvpn down needed ==="
run "deadline passed, never connected"       "nothing to report"              down "up asia1 $((now-200)) $((now-60))"
run "stale 3-field intent (your case)"       "nothing to report"              down "up asia1 $((now-2951))"
run "same request again -> still no banner"  "nothing to report"              down "up asia1 $((now-2951))" "$((now-2951)) 1 0"
run "opt-in banner for a failed up"          "TEST-notify: VPN not connected"  down "up asia1 $((now-200)) $((now-60))" "" "UP_FAIL_NOTIFY=1"

echo "=== a real drop still banners ==="
run "connected (ok flag) then gone"          "TEST-notify: VPN dropped"       down "up asia1 $((now-200)) $((now-60)) ok"
run "connected (state file) then gone"       "TEST-notify: VPN dropped"       down "up asia1 $((now-200)) $((now-60))" "$((now-200)) 0 1"
run "already reported for that request"      "already notified"               down "up asia1 $((now-200)) $((now-60)) ok" "$((now-200)) 1 1"
echo "=== ppp0 up but the probe is silent: streak, banner, auto-down ==="
run_times "1st dead tick: silent streak"        "unreachable 1/3"            unreachable "up asia1 $((now-200)) $((now-60)) ok" 1 "" "TEST-down"
run_times "2nd dead tick: still silent"         "unreachable 2/3"            unreachable "up asia1 $((now-200)) $((now-60)) ok" 2 "" "TEST-down"
run_times "3rd dead tick: banner + auto-down"   "TEST-down: would run fvpn down" unreachable "up asia1 $((now-200)) $((now-60)) ok" 3
run_times "3rd dead tick: banner text"          "TEST-notify: VPN dead"      unreachable "up asia1 $((now-200)) $((now-60)) ok" 3
run_times "DNS_AUTODOWN=0 keeps the tunnel"     "notified: unreachable 3/3"  unreachable "up asia1 $((now-200)) $((now-60)) ok" 3 "DNS_AUTODOWN=0" "TEST-down"
run_times "custom threshold DNS_FAIL_MAX=2"     "TEST-down: would run fvpn down" unreachable "up asia1 $((now-200)) $((now-60)) ok" 2 "DNS_FAIL_MAX=2"

echo "=== unchanged behaviour ==="
run "tunnel up after request"                "ok: tunnel up"                  up   "up asia1 $((now-40)) $((now+10))"
run "deliberate down"                        "request down"                   down "down - $now"
run "no request recorded"                    "no request recorded"            down ""

echo
echo "   passed=$pass failed=$fail"
rm -rf "$T"
[ "$fail" -eq 0 ]

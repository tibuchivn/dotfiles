#!/bin/bash
# One-time setup: unattended openfortivpn for the 4 Internet Brands SSL VPN gateways.
# Run it yourself in a Terminal window: bash ~/tung/dotfiles/fvpn/fvpn-setup.sh
#
# Design points, each answering a known failure mode:
#   * The VPN password lives in the login keychain, typed straight into security(1)'s
#     prompt: never in this script's argv, never in a config file, never printed.
#   * The root helper never executes anything from a user-writable directory.
#     /opt/homebrew is owned by the admin user, so running the brew binary as root
#     through a NOPASSWD entry would let any user-level code become root. openfortivpn
#     and its dylibs are therefore copied to /usr/local/libexec/fvpn (root-owned),
#     load commands rewritten to @executable_path/@loader_path, ad-hoc re-signed.
#   * PATH in the root helper and the pinentry stub is /usr/bin:/bin:/usr/sbin:/sbin
#     and every external command is called by absolute path.
#   * Gateway certs are never trusted on first use via a substring match: platform
#     trust (full chain + hostname, AIA-capable) is proven with curl first, the exact
#     hostname is re-checked with OpenSSL -checkhost, then the digest is pinned.
#     some gateways do not send their intermediates, so `openssl s_client
#     -verify_return_error` reports code 20 there while curl succeeds - hence curl.
#
# Installs:
#   login keychain item "fvpn-vpn-password"
#   /usr/local/libexec/fvpn/            pinned openfortivpn + libssl/libcrypto (root)
#   /usr/local/libexec/fvpn-pinentry    Assuan pinentry stub (root, keychain -> openfortivpn)
#   /usr/local/etc/openfortivpn/*.conf  host/port/user/pinned cert, no password
#   /usr/local/sbin/fvpn-root           root helper: up|down|status
#   /usr/local/bin/fvpn                 user wrapper: sudo -n fvpn-root
#   /etc/sudoers.d/fvpn                 NOPASSWD + secure_path, scoped to fvpn-root

set -euo pipefail
umask 077
# the whole setup runs with a fixed, non-user-writable PATH
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

OFPDIR=/usr/local/libexec/fvpn
STUB=/usr/local/libexec/fvpn-pinentry
CONFDIR=/usr/local/etc/openfortivpn
ME=$(id -un)
OFP_SRC=/opt/homebrew/bin/openfortivpn

# Tenant-specific values live in fvpn.local.sh next to this script (gitignored).
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FVPN_LOCAL="$SCRIPT_DIR/fvpn.local.sh"
if [ -r "$FVPN_LOCAL" ]; then . "$FVPN_LOCAL"; fi
: "${GATEWAY_DOMAIN:?set GATEWAY_DOMAIN in fvpn.local.sh}"
: "${VPN_USER:?set VPN_USER in fvpn.local.sh}"
GATEWAY_PREFIX="${GATEWAY_PREFIX:-vpn-}"
KEYCHAIN_ITEM="${KEYCHAIN_ITEM:-fvpn-vpn-password}"
ITEM="$KEYCHAIN_ITEM"
VPNUSER="$VPN_USER"

# The gateway list is derived from FortiClient's own profiles (SSL VPN only), so adding a
# profile in FortiClient and re-running this script is all it takes. Falls back to
# FVPN_GATEWAYS from fvpn.local.sh when the plist is unreadable.
FCT_PLIST="/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"
discover_gateways() {
  local n vt srv
  [ -r "$FCT_PLIST" ] || return 1
  /usr/libexec/PlistBuddy -c "Print :Profiles" "$FCT_PLIST" 2>/dev/null \
    | /usr/bin/sed -n 's/^[[:space:]]*\([A-Za-z0-9_.-]*\) = Dict {$/\1/p' \
    | while IFS= read -r n; do
        vt=$(/usr/libexec/PlistBuddy -c "Print :Profiles:$n:VpnType" "$FCT_PLIST" 2>/dev/null)
        srv=$(/usr/libexec/PlistBuddy -c "Print :Profiles:$n:Server" "$FCT_PLIST" 2>/dev/null)
        [ "$vt" = "0" ] || continue
        case "$srv" in
          "${GATEWAY_PREFIX}"*".${GATEWAY_DOMAIN}")
            gw=${srv#"${GATEWAY_PREFIX}"}
            printf '%s\n' "${gw%".${GATEWAY_DOMAIN}"}"
            ;;
        esac
      done
}
GATEWAYS=$(discover_gateways | /usr/bin/sort -u | /usr/bin/tr '\n' ' ' || true)
GATEWAYS=${GATEWAYS% }
[ -n "$GATEWAYS" ] || GATEWAYS="${FVPN_GATEWAYS:-}"
[ -n "$GATEWAYS" ] || die "no gateways found: add VPN profiles in FortiClient or set FVPN_GATEWAYS in fvpn.local.sh"

say() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- helpers

find_openssl() {
  local c
  for c in /opt/homebrew/opt/openssl@4/bin/openssl \
           /opt/homebrew/opt/openssl@3/bin/openssl \
           /opt/homebrew/bin/openssl \
           /usr/bin/openssl; do
    [ -x "$c" ] || continue
    if "$c" x509 -help 2>&1 | /usr/bin/grep -q -- '-checkhost'; then printf '%s' "$c"; return 0; fi
  done
  return 1
}

# 1) platform-verified HTTPS (full chain + hostname, AIA capable)
# 2) leaf SAN must match this exact hostname (not a substring)
# 3) not expiring soon
# echoes the sha256 digest
gateway_digest() {
  local host=$1 pem=$2
  # -q ignores ~/.curlrc; --noproxy/--proto stop a user-level proxy or downgrade
  curl -q -sS -f --noproxy '*' --proto '=https' -o /dev/null --max-time 15 \
    "https://$host/remote/login" \
    || die "$host: platform TLS verification failed (chain/hostname). Refusing to pin."
  "$OPENSSL" s_client -connect "$host:443" -servername "$host" -showcerts </dev/null 2>/dev/null \
    | /usr/bin/sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | /usr/bin/head -n 100 > "$pem"
  [ -s "$pem" ] || die "$host: could not read leaf certificate"
  "$OPENSSL" x509 -in "$pem" -noout -checkhost "$host" >/dev/null 2>&1 \
    || die "$host: certificate does not match this hostname"
  # This is the gate that matters: the EXACT certificate we are about to pin must be
  # trusted by the platform for this hostname. curl above is a separate connection, so a
  # MITM that fingerprints clients (JA3) could hand curl a good cert and this openssl
  # connection a self-signed one with a matching SAN; verify-cert closes that gap.
  /usr/bin/security verify-cert -q -p ssl -c "$pem" -n "$host" >/dev/null 2>&1 \
    || die "$host: the fetched certificate is not trusted by the platform for this hostname"
  "$OPENSSL" x509 -in "$pem" -noout -checkend 0 >/dev/null 2>&1 \
    || die "$host: certificate is expired"
  if ! "$OPENSSL" x509 -in "$pem" -noout -checkend 1814400 >/dev/null 2>&1; then
    printf '   WARNING: %s cert expires %s\n' "$host" \
      "$("$OPENSSL" x509 -in "$pem" -noout -enddate | /usr/bin/sed 's/.*=//')" >&2
    printf '            re-run this setup after the gateway renews it, or the pinned digest stops matching.\n' >&2
  fi
  "$OPENSSL" x509 -in "$pem" -noout -fingerprint -sha256 \
    | /usr/bin/sed 's/.*=//' | /usr/bin/tr -d ':' | /usr/bin/tr 'A-Z' 'a-z'
}

# Homebrew dylib dependencies of a Mach-O file, one per line (no word splitting)
hb_deps() {
  /usr/bin/otool -L "$1" | /usr/bin/sed -n '2,$p' | /usr/bin/awk '{print $1}' \
    | /usr/bin/grep '^/opt/homebrew/' | /usr/bin/sort -u
}

# Copy a binary plus every Homebrew dylib it needs into $2, rewrite load commands so
# nothing resolves outside that directory, ad-hoc re-sign, then prove it runs clean.
build_pinned_copy() {
  local src=$1 out=$2 bin base dep f queue seen refs
  /bin/mkdir -p "$out"
  bin="$out/$(/usr/bin/basename "$src")"
  /bin/cp -L "$src" "$bin"
  queue=$bin
  seen=" "
  while [ -n "$queue" ]; do
    set -- $queue
    queue=""
    for f in "$@"; do
      while IFS= read -r dep; do
        [ -n "$dep" ] || continue
        base=$(/usr/bin/basename "$dep")
        case "$seen" in *" $base "*) continue ;; esac
        seen="$seen$base "
        /bin/cp -L "$dep" "$out/$base"
        queue="$queue $out/$base"
      done < <(hb_deps "$f")
    done
  done
  for f in "$out"/*.dylib; do
    [ -e "$f" ] || continue
    base=$(/usr/bin/basename "$f")
    /usr/bin/install_name_tool -id "@rpath/$base" "$f" 2>/dev/null || true
    while IFS= read -r dep; do
      [ -n "$dep" ] || continue
      /usr/bin/install_name_tool -change "$dep" "@loader_path/$(/usr/bin/basename "$dep")" "$f"
    done < <(hb_deps "$f")
  done
  while IFS= read -r dep; do
    [ -n "$dep" ] || continue
    /usr/bin/install_name_tool -change "$dep" "@executable_path/$(/usr/bin/basename "$dep")" "$bin"
  done < <(hb_deps "$bin")
  for f in "$out"/*; do
    [ -f "$f" ] || continue
    /bin/chmod 755 "$f"
    /usr/bin/codesign -f -s - "$f" >/dev/null 2>&1 || die "codesign failed: $f"
  done
  refs=$(/usr/bin/otool -L "$out"/* 2>/dev/null | /usr/bin/grep -c '/opt/homebrew/' || true)
  [ "${refs:-1}" = "0" ] || die "pinned copy still references Homebrew paths ($refs)"
  "$bin" --version >/dev/null 2>&1 || die "pinned copy does not run"
}

# allows tests to source this file without running main
if [ "${FVPN_LIB_ONLY:-0}" = 1 ]; then return 0 2>/dev/null || exit 0; fi

# ---------------------------------------------------------------- main

say "== 1/7 sudo (your macOS password) =="
sudo -v

say "== 2/7 VPN password for $VPNUSER -> login keychain item '$ITEM' =="
RESET_CRED=0
case "${1:-}" in
  --reset-cred) RESET_CRED=1 ;;
  "") : ;;
  *) die "unknown argument '${1}' (only --reset-cred is accepted)" ;;
esac
if [ "$RESET_CRED" = 0 ] && security find-generic-password -s "$ITEM" >/dev/null 2>&1; then
  say "   item already exists; keeping it (pass --reset-cred to replace the password)"
else
  say "   security(1) prompts twice; input is not echoed and never enters this script."
  security add-generic-password -U -a "$ME" -s "$ITEM" \
    -l "FortiGate SSL VPN ($VPNUSER)" -T /usr/bin/security -w
  security find-generic-password -s "$ITEM" >/dev/null 2>&1 || die "keychain write failed"
  say "   stored and readable (value not shown)"
fi

OPENSSL=$(find_openssl) || die "need OpenSSL with -checkhost (brew install openssl@3)"
say "== 3/7 verifying gateway certificates (platform trust + exact hostname) =="
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
: > "$TMP/fps"
for n in $GATEWAYS; do
  host="${GATEWAY_PREFIX}${n}.${GATEWAY_DOMAIN}"
  if ! fp=$(gateway_digest "$host" "$TMP/$n.pem"); then
    die "$host: certificate verification failed, nothing pinned"
  fi
  case "$fp" in
    [0-9a-f][0-9a-f]*) : ;;
    *) die "$host: no usable certificate digest" ;;
  esac
  [ ${#fp} -eq 64 ] || die "$host: unexpected digest length (${#fp})"
  printf '%s %s\n' "$n" "$fp" >> "$TMP/fps"
  say "   $host  $fp"
done

say "== 4/7 building a root-owned copy of openfortivpn ($OFPDIR) =="
build_pinned_copy "$OFP_SRC" "$TMP/pinned"
# parents explicitly 755: `install -d` creates missing ancestors with 0777 & umask,
# and our umask is 077, which would leave /usr/local/libexec unlistable by admin
sudo install -d -m 755 -o root -g wheel /usr/local/libexec /usr/local/etc /usr/local/sbin /usr/local/bin
sudo install -d -m 755 -o root -g wheel "$OFPDIR"
sudo install -m 755 -o root -g wheel "$TMP"/pinned/* "$OFPDIR/"
say "   pinned: $(/bin/ls "$TMP/pinned" | /usr/bin/tr '\n' ' ')"

say "== 5/7 writing configs (no password) into $CONFDIR =="
sudo install -d -m 755 -o root -g wheel "$CONFDIR"
while read -r n fp; do
  cat > "$TMP/$n.conf" <<EOF
# openfortivpn - ${GATEWAY_PREFIX}${n}.${GATEWAY_DOMAIN}  (generated $(date +%F))
# No password here: supplied by $STUB from the login keychain.
host = ${GATEWAY_PREFIX}${n}.${GATEWAY_DOMAIN}
port = 443
username = $VPNUSER

trusted-cert = $fp
set-dns = 1
pppd-use-peerdns = 1
EOF
  sudo install -m 600 -o root -g wheel "$TMP/$n.conf" "$CONFDIR/$n.conf"
done < "$TMP/fps"

cat > "$TMP/fvpn-pinentry" <<'EOS'
#!/bin/bash
# Assuan pinentry stub: supplies the VPN password from the macOS login keychain.
# Read via `-g`, not `-w`: -w hex-dumps any value containing non-ASCII bytes, which
# is indistinguishable from a password that merely looks like hex ("abc123" comes
# back plain, "café" comes back as hex). -g is unambiguous: `password: 0x<hex>`
# vs `password: "<plain>"`.
# Runs as root (child of root openfortivpn): sanitised PATH, absolute paths only.
# No trailing "OK" after "D" on purpose: openfortivpn does not use libassuan's
# assuan_transact. Its own reader (src/userinput.c, pinentry_read) reads exactly ONE
# line per exchange and treats "D <data>" as a complete, successful response, then
# closes the pipes - an extra "OK" would write into a closed pipe.
# Corollary: EVERY command needs exactly one reply line, SETKEYINFO included. Skipping
# one shifts the stream by a line and the final GETPIN read blocks forever.
set -uo pipefail
umask 077
PATH=/usr/bin:/bin:/usr/sbin:/sbin
FVPN_OWNER="${FVPN_OWNER:-__OWNER__}"
ITEM="${FVPN_KEYCHAIN_ITEM:-__ITEM__}"

# Never log the secret, only which hint arrived and how it was answered: that is what
# shows whether this gateway's token request matches the "_otp" suffix or not.
note() { { printf '%s %s\n' "$(/bin/date '+%F %T')" "$*" >> /var/log/fvpn-pinentry.log; } 2>/dev/null || true; }

fetch_raw() {
  if [ "$(/usr/bin/id -u)" = 0 ] && [ "$FVPN_OWNER" != root ]; then
    /usr/bin/sudo -n -u "$FVPN_OWNER" /usr/bin/security find-generic-password -s "$ITEM" -g 2>&1 >/dev/null
  else
    /usr/bin/security find-generic-password -s "$ITEM" -g 2>&1 >/dev/null
  fi
}

# `password: ...` line -> Assuan "D" value (percent-escaped), byte-wise
pct_from_attr() {
  printf '%s\n' "$1" | /usr/bin/perl -ne '
    next unless /^password: (.*)$/;
    my $v = $1;
    my @b;
    if ($v =~ /^0x([0-9A-Fa-f]+)/) {
      @b = map { hex($_) } ($1 =~ /(..)/g);
    } elsif ($v =~ /^"(.*)"$/) {
      my $s = $1; $s =~ s/\\(["\\])/$1/g;
      @b = map { ord($_) } split //, $s;
    } else {
      @b = map { ord($_) } split //, $v;
    }
    print join("", map { chr($_) =~ /[A-Za-z0-9\-_.~]/ ? chr($_) : sprintf("%%%02X", $_) } @b);
  '
}

hint=""
prompt=""
printf 'OK fvpn keychain pinentry\n'
while IFS= read -r line; do
  case "$line" in
    SETKEYINFO*) hint="${line#SETKEYINFO }"; printf 'OK\n' ;;
    SETPROMPT*) prompt="${line#SETPROMPT }"; printf 'OK\n' ;;
    GETPIN*)
      # openfortivpn asks for the FortiToken code through this same pinentry channel, so
      # ONLY the account-password request may be answered from the keychain. Any token
      # request must be refused, otherwise the password is submitted as the token.
      # Hints, straight from the source:
      #   password  "<user>_<realm>_<host>_password"  src/main.c
      #   token via login form  "..._otp"             src/http.c try_otp_auth()
      #   token via tokeninfo   "..._2fa"             src/http.c auth_log_in()
      # The password prompt is "VPN account password: ", uri-escaped by openfortivpn.
      note "hint=${hint:-<none>} prompt=${prompt:-<none>}"
      is_pw=0
      case "$hint" in
        *_password) is_pw=1 ;;
        "")
          [ "$prompt" = "VPN%20account%20password%3A%20" ] && is_pw=1
          ;;
      esac
      if [ "$is_pw" != 1 ]; then
        note "  -> refused: second factor requested, not the account password"
        printf 'ERR 83886179 no token source (hint %s) - approve on the phone, or: fvpn manual <gateway>\n' "${hint:-<none>}"
        exit 1
      fi
      raw=$(fetch_raw)
      if [ -z "$raw" ] || ! printf '%s' "$raw" | /usr/bin/grep -q '^password: '; then
        note "  -> keychain read failed (item $ITEM)"
        printf 'ERR 83886179 no credential in keychain (item: %s)\n' "$ITEM"
        exit 1
      fi
      note "  -> answered from keychain"
      printf 'D %s\n' "$(pct_from_attr "$raw")"
      ;;
    BYE*) exit 0 ;;
    *) printf 'OK\n' ;;
  esac
done
EOS
# perl reads the owner from the environment: a username containing & or | cannot
# corrupt the substitution the way sed's replacement text would.
FVPN_OWNER="$ME" /usr/bin/perl -pi -e 's/__OWNER__/$ENV{FVPN_OWNER}/g' "$TMP/fvpn-pinentry"
FVPN_ITEM="$KEYCHAIN_ITEM" /usr/bin/perl -pi -e 's/__ITEM__/$ENV{FVPN_ITEM}/g' "$TMP/fvpn-pinentry"

cat > "$TMP/fvpn-root" <<'EOS'
#!/bin/bash
# Root helper: the only command sudoers lets this user run without a password.
# Everything executed from here is root-owned and addressed by absolute path.
set -uo pipefail
umask 077
PATH=/usr/bin:/bin:/usr/sbin:/sbin
CONFDIR=/usr/local/etc/openfortivpn
OFP=/usr/local/libexec/fvpn/openfortivpn
PINENTRY=/usr/local/libexec/fvpn-pinentry
OFP_DIR=/usr/local/libexec/fvpn
INTENT=/var/log/fvpn-intent   # read by the user-level watcher (ai.fvpn.watch)

usage() { echo "usage: fvpn-root list | up <gateway> [seconds] | down [gateway] | manual <gateway> | status | logs <gateway> [lines]" >&2; exit 2; }
action="${1:-}"; name="${2:-}"; arg3="${3:-}"
case "$action" in
  up|logs|manual) [ -n "$name" ] || usage ;;
  down|status|list) : ;;   # only one tunnel can exist, so `down` does not need the name
  *) usage ;;
esac
# gateway names are plain slugs; which ones exist is decided by the config files
case "$name" in
  *[!a-z0-9_-]*) usage ;;
esac
CONF="$CONFDIR/${name:-none}.conf"
LOG="/var/log/fvpn-${name:-none}.log"

if [ "$action" = up ] || [ "$action" = manual ]; then
  [ -r "$CONF" ] || { echo "missing config $CONF (re-run setup)" >&2; exit 2; }
elif [ "$action" = down ] && [ -n "$name" ]; then
  [ -r "$CONF" ] || { echo "missing config $CONF (re-run setup)" >&2; exit 2; }
fi

# Shared by `up` and `manual`: never execute a binary, or trust a config, that a non-root
# user could have written. `manual` used to skip this check, which defeated the whole point.
verify_root_files() {
  local d f perm host
  for d in /usr/local /usr/local/libexec /usr/local/etc "$CONFDIR" "$OFP_DIR"; do
    [ -d "$d" ] || { echo "refuse: $d is missing (re-run setup)" >&2; return 1; }
    [ "$(/usr/bin/stat -f %Su "$d")" = root ] || { echo "refuse: $d is not root-owned" >&2; return 1; }
    perm=$(/usr/bin/stat -f %p "$d")
    [ $(( 0$perm & 022 )) -eq 0 ] || { echo "refuse: $d is group/world writable" >&2; return 1; }
  done
  for f in "$OFP" "$PINENTRY"; do
    [ -x "$f" ] || { echo "missing $f (re-run setup)" >&2; return 1; }
    [ "$(/usr/bin/stat -f %Su "$f")" = root ] || { echo "refuse: $f is not root-owned" >&2; return 1; }
    perm=$(/usr/bin/stat -f %p "$f")
    [ $(( 0$perm & 022 )) -eq 0 ] || { echo "refuse: $f is group/world writable" >&2; return 1; }
  done
  if [ -n "$name" ]; then
    [ -r "$CONF" ] || { echo "missing config $CONF (re-run setup)" >&2; return 1; }
    [ "$(/usr/bin/stat -f %Su "$CONF")" = root ] || { echo "refuse: $CONF is not root-owned" >&2; return 1; }
    perm=$(/usr/bin/stat -f %p "$CONF")
    [ $(( 0$perm & 022 )) -eq 0 ] || { echo "refuse: $CONF is group/world writable" >&2; return 1; }
    # The config decides where the password is sent and which cert is pinned, so a tampered
    # `host =` line is a credential-exfiltration path. Only the expected gateway is allowed.
    host=$(/usr/bin/awk -F' *= *' '$1=="host"{print $2; exit}' "$CONF")
    [ "$host" = "__PREFIX__${name}.__DOMAIN__" ] || {
      echo "refuse: $CONF points at '${host:-<none>}', expected __PREFIX__${name}.__DOMAIN__" >&2
      return 1
    }
  fi
  return 0
}

if [ "$action" = up ] || [ "$action" = manual ]; then
  verify_root_files || exit 1
fi

gw_pids() { /usr/bin/pgrep -f "openfortivpn .*${CONF}" || true; }
tun_pid()  { /usr/bin/pgrep -f "pppd .*${CONF}" || true; }
any_gw()   { /usr/bin/pgrep -f "openfortivpn .*${CONFDIR}/" || true; }
any_tun()  { /usr/bin/pgrep -f "pppd .*${CONFDIR}/" || true; }

show_status() {
  if /sbin/ifconfig ppp0 2>/dev/null | /usr/bin/grep -q 'inet '; then
    echo "connected  ip=$(/sbin/ifconfig ppp0 | /usr/bin/awk '/inet /{print $2; exit}')"
    /usr/sbin/netstat -rn -f inet 2>/dev/null | /usr/bin/awk '$1=="default"{print "default -> "$NF; exit}'
    /usr/sbin/scutil --dns 2>/dev/null | /usr/bin/awk '/nameserver\[0\]/{print "dns "$3; exit}'
  else
    echo "disconnected"
  fi
}

case "$action" in
  up)
    wait_s="${arg3:-30}"
    case "$wait_s" in ''|*[!0-9]*) echo "seconds must be a number" >&2; exit 2 ;; esac
    [ "$wait_s" -ge 15 ] && [ "$wait_s" -le 900 ] || { echo "seconds must be 15..900" >&2; exit 2; }
    p=$(gw_pids)
    if [ -n "$p" ]; then echo "already running pid=$p"; show_status; exit 0; fi
    if /sbin/ifconfig ppp0 >/dev/null 2>&1; then
      echo "ERROR: ppp0 already exists (FortiClient or another tunnel is up); disconnect it first" >&2
      exit 1
    fi
    [ -f "$LOG" ] || : > "$LOG" 2>/dev/null || true
    /bin/chmod 600 "$LOG" 2>/dev/null || true   # log holds gateway, user, DNS, addresses
    # No --persistent: openfortivpn's persistent loop re-runs run_tunnel every <interval>
    # whatever the reason, so a stale keychain password would hammer the gateway every
    # few seconds and trip an AD lockout. One attempt per invocation is the safe default.
    echo "waiting up to ${wait_s}s: approve the FortiToken push on your phone (or type the OTP with: fvpn manual $name)"
    # record intent so the user-level watcher knows a connection was requested
    printf 'up %s %s\n' "$name" "$(/bin/date +%s)" > "$INTENT" 2>/dev/null || true
    /bin/chmod 644 "$INTENT" 2>/dev/null || true
    /usr/bin/nohup "$OFP" -c "$CONF" --pinentry="$PINENTRY" >>"$LOG" 2>&1 &
    ofp_pid=$!
    i=0
    max_i=$((wait_s * 2))
    while [ $i -lt $max_i ]; do   # poll every 0.5s until the interface is up
      i=$((i+1))
      /bin/sleep 0.5
      if /sbin/ifconfig ppp0 2>/dev/null | /usr/bin/grep -q 'inet '; then
        # routes land a moment after the interface: report the real default route
        j=0
        while [ $j -lt 12 ]; do
          if /usr/sbin/netstat -rn -f inet 2>/dev/null \
             | /usr/bin/awk '$1=="default"{print $NF; exit}' | /usr/bin/grep -qx ppp0; then
            break
          fi
          j=$((j+1)); /bin/sleep 0.5
        done
        echo "$name: up"; show_status; exit 0
      fi
      if ! /bin/kill -0 "$ofp_pid" 2>/dev/null; then
        echo "ERROR: openfortivpn exited before the tunnel came up. Last log lines ($LOG):" >&2
        /usr/bin/tail -n 12 "$LOG" >&2 2>/dev/null || true
        # openfortivpn may have spawned pppd before dying: an orphan pppd holds ppp0
        t=$(tun_pid); [ -n "$t" ] && /bin/kill $t 2>/dev/null || true
        exit 1
      fi
    done
    echo "ERROR: no tunnel after ${wait_s}s - FortiToken push not approved, or the login was rejected. Last log lines ($LOG):" >&2
    /usr/bin/tail -n 10 "$LOG" >&2 2>/dev/null || true
    # never leave an orphan behind: it would hold ppp0 and block the next up
    /bin/kill "$ofp_pid" 2>/dev/null || true
    /bin/sleep 1
    p=$(gw_pids)
    [ -n "$p" ] && /bin/kill $p 2>/dev/null || true
    t=$(tun_pid)
    [ -n "$t" ] && /bin/kill $t 2>/dev/null || true
    exit 1
    ;;
  down)
    # record the intent first, even if nothing is running: otherwise a stale "up" request
    # survives and the watcher would blame fvpn for a drop it never caused
    printf 'down - %s\n' "$(/bin/date +%s)" > "$INTENT" 2>/dev/null || true
    /bin/chmod 644 "$INTENT" 2>/dev/null || true
    if [ -n "$name" ]; then
      p=$(gw_pids); t=$(tun_pid); label="$name"
    else
      p=$(any_gw); t=$(any_tun); label="tunnel"
    fi
    if [ -z "$p" ]; then echo "not running"; show_status; exit 0; fi
    /bin/kill $p 2>/dev/null || true
    i=0
    while [ $i -lt 20 ]; do
      i=$((i+1)); /bin/sleep 0.5
      /bin/kill -0 $p 2>/dev/null || break
    done
    [ -n "$t" ] && /bin/kill $t 2>/dev/null || true
    echo "$label: down"; show_status
    # if ppp0 survives, say so instead of pretending it worked
    if /sbin/ifconfig ppp0 >/dev/null 2>&1; then
      echo "WARNING: ppp0 still exists; check for another VPN client holding it" >&2
      exit 1
    fi
    ;;
  manual)
    # Interactive fallback for when the FortiToken push does not show up: run in a
    # visible Terminal so the password and the token code are typed on the tty.
    if /sbin/ifconfig ppp0 >/dev/null 2>&1; then
      echo "ERROR: ppp0 already exists; run: fvpn down $name" >&2; exit 1
    fi
    echo "interactive: VPN password first, then the FortiToken code when asked. Ctrl-C aborts."
    printf 'up %s %s\n' "$name" "$(/bin/date +%s)" > "$INTENT" 2>/dev/null || true
    /bin/chmod 644 "$INTENT" 2>/dev/null || true
    exec "$OFP" -c "$CONF"
    ;;
  logs)
    lines="${arg3:-40}"
    case "$lines" in ''|*[!0-9]*) echo "log-lines must be a number" >&2; exit 2 ;; esac
    [ "$lines" -ge 1 ] && [ "$lines" -le 500 ] || { echo "log-lines must be 1..500" >&2; exit 2; }
    [ -r "$LOG" ] || { echo "no log yet for $name ($LOG)" >&2; exit 1; }
    echo "--- $LOG (last $lines lines) ---"
    /usr/bin/tail -n "$lines" "$LOG"
    ;;
  list)
    echo "gateways available in $CONFDIR:"
    found=0
    for f in "$CONFDIR"/*.conf; do
      [ -e "$f" ] || continue
      found=1
      gw=$(/usr/bin/basename "$f" .conf)
      if [ -n "$(/usr/bin/pgrep -f "openfortivpn .*$f" 2>/dev/null || true)" ]; then
        echo "  $gw  <- connected"
      else
        echo "  $gw"
      fi
    done
    [ "$found" = 1 ] || echo "  (none - run the setup script)"
    echo "usage: fvpn up <gateway> [seconds] | fvpn down [gateway] | fvpn manual <gateway>"
    ;;
  status) show_status ;;
  *) usage ;;
esac
EOS

FVPN_GW_PREFIX="$GATEWAY_PREFIX" FVPN_GW_DOMAIN="$GATEWAY_DOMAIN" \
  /usr/bin/perl -pi -e 's/__PREFIX__/$ENV{FVPN_GW_PREFIX}/g; s/__DOMAIN__/$ENV{FVPN_GW_DOMAIN}/g' "$TMP/fvpn-root"

cat > "$TMP/fvpn" <<'EOS'
#!/bin/bash
# User wrapper: the only thing sudoers lets this user run without a password.
exec /usr/bin/sudo -n /usr/local/sbin/fvpn-root "$@"
EOS

say "== 6/7 installing stub, helper, wrapper, sudoers rule =="
sudo install -d -m 755 -o root -g wheel /usr/local/libexec
sudo install -m 755 -o root -g wheel "$TMP/fvpn-pinentry" "$STUB"
sudo install -m 755 -o root -g wheel "$TMP/fvpn-root"    /usr/local/sbin/fvpn-root
sudo install -m 755 -o root -g wheel "$TMP/fvpn"         /usr/local/bin/fvpn
{
  printf 'Defaults!/usr/local/sbin/fvpn-root secure_path="/usr/bin:/bin:/usr/sbin:/sbin", env_reset\n'
  printf '%s ALL=(root) NOPASSWD: /usr/local/sbin/fvpn-root\n' "$ME"
} > "$TMP/sudoers"
sudo install -m 440 -o root -g wheel "$TMP/sudoers" /etc/sudoers.d/fvpn
sudo visudo -cf /etc/sudoers.d/fvpn

say "== 7/7 self-tests =="
sudo -v   # these two -n calls are not covered by the NOPASSWD rule; refresh the timestamp
sudo -n "$OFPDIR/openfortivpn" --version >/dev/null 2>&1 \
  && say "   ok: pinned openfortivpn runs as root" \
  || die "pinned openfortivpn does not run"
stub_out=$(printf 'SETTITLE VPN Password\nSETDESC VPN Requires a Password\nSETKEYINFO a_b_password\nSETPROMPT VPN account password: \nGETPIN\nBYE\n' | sudo -n "$STUB" 2>/dev/null) || true
# openfortivpn reads exactly one reply line per command (greeting + 4x SET* + GETPIN),
# so the transcript must be OK,OK,OK,OK,OK,D in that order. Assert the order, not just
# counts: one missing reply shifts the whole stream and the GETPIN read blocks forever.
transcript=$(printf '%s\n' "$stub_out" \
  | /usr/bin/awk '/^D /{print "D"; next} /^OK/{print "OK"; next} NF{print "?"}' \
  | /usr/bin/paste -sd';' -)
if [ "$transcript" = "OK;OK;OK;OK;OK;D" ]; then
  say "   ok: assuan dialogue in order (5x OK then 1x D, value not shown)"
else
  die "pinentry stub dialogue unexpected (got: ${transcript:-empty}) - check the keychain item"
fi
# setup PATH is sanitised (no /usr/local/bin), so call the wrapper by absolute path
/usr/local/bin/fvpn status || true

say ""
say "Done. Usage:  fvpn up asia1 | fvpn status | fvpn down asia1"
say "Gateways: $GATEWAYS   Logs: /var/log/fvpn-<gateway>.log"
say "A Homebrew upgrade of openfortivpn does NOT change what runs as root;"
say "re-run this script to refresh the pinned copy."

# fvpn — FortiGate SSL VPN from the macOS command line

FortiClient on macOS ships **no** CLI to connect a tunnel (`epctrl` only does EMS
registration, `fcconfig` only imports/exports profiles). This directory makes the same
SSL VPN usable from a shell — and therefore from scripts, Hammerspoon, or an assistant —
with `openfortivpn` underneath.

What you get:

| command | what it does |
| --- | --- |
| `fvpn up <gateway> [seconds]` | connect (waits for the FortiToken approval, default 30s) |
| `fvpn down [gateway]` | disconnect (gateway is optional — there is only one tunnel) |
| `fvpn manual <gateway>` | interactive fallback: type password + OTP in a terminal |
| `fvpn status` | `connected ip=…` / `default -> ppp0` / `dns …`, or `disconnected` |
| `fvpn list` | gateways installed here, marking the connected one |
| `fvpn logs <gateway> [lines]` | tail `/var/log/fvpn-<gateway>.log` |

Two optional extras:

* `fvpn-watch.sh` + `ai.fvpn.watch.plist` — a launchd agent that posts a macOS
  notification when the tunnel drops or never comes up.
* the VPN line in the Hammerspoon `opt+T` alert (see `../.hammerspoon/private/config.lua`).

## Requirements

* macOS 13+ (Apple Silicon or Intel), Homebrew.
* `brew install openfortivpn`.
* The password for the VPN account, and FortiToken Mobile (push approval) or an OTP.
* Optional: FortiClient installed with your VPN profiles, which the setup script reads to
  discover the gateways.

## Install

```bash
brew install openfortivpn

cd ~/tung/dotfiles/fvpn
cp fvpn.local.example.sh fvpn.local.sh      # then edit: VPN_USER, GATEWAY_DOMAIN, ...
$EDITOR fvpn.local.sh

bash fvpn-setup.sh
```

`fvpn-setup.sh` asks for your macOS password once, then:

1. stores the VPN password in the **login keychain** (item named by `KEYCHAIN_ITEM`);
2. discovers the gateways from FortiClient's `vpn.plist` (SSL profiles whose server is
   `<GATEWAY_PREFIX><name>.<GATEWAY_DOMAIN>`), or uses `FVPN_GATEWAYS` from
   `fvpn.local.sh`;
3. verifies each gateway certificate (platform trust + exact hostname) and pins its
   SHA-256;
4. installs a **root-owned copy** of `openfortivpn` plus its dylibs under
   `/usr/local/libexec/fvpn/`, and the pinentry stub `/usr/local/libexec/fvpn-pinentry`;
5. writes `/usr/local/etc/openfortivpn/<gateway>.conf` (mode 600, **no password**);
6. installs `/usr/local/sbin/fvpn-root` (the root helper) and `/usr/local/bin/fvpn`
   (the user wrapper), plus one `NOPASSWD` sudoers rule for that helper;
7. self-tests: the pinned binary runs as root and the stub answers the pinentry
   dialogue from the keychain.

Re-run it any time: it keeps the existing keychain item (use `--reset-cred` to replace
the stored password) and refreshes configs, pins and the pinned binary.

### Optional: drop notifications

```bash
mkdir -p ~/bin
ln -sf ~/tung/dotfiles/fvpn/fvpn-watch.sh ~/bin/fvpn-watch.sh
cp ai.fvpn.watch.plist ~/Library/LaunchAgents/
# adjust the ProgramArguments path inside the plist if your home differs
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.fvpn.watch.plist
launchctl print gui/$(id -u)/ai.fvpn.watch | grep -E 'state|runs|run interval'
```

Notifications appear as **Script Editor**; allow them in System Settings → Notifications.
It fires only when `fvpn up` was requested but the tunnel is not healthy — never for a
deliberate `fvpn down`, never on a fresh login with no VPN requested, and at most once per
request.

## Usage

```bash
fvpn list                  # asia1  <- connected / east2 / eu1 / west1
fvpn up asia1              # approve the FortiToken push when it arrives
fvpn up asia1 90           # allow 90s for the approval (15..900)
fvpn status
fvpn down                  # no gateway name needed
fvpn manual asia1          # push never shows up: type password then OTP
fvpn logs asia1 40
```

## How it works, and why it is built this way

* **Password never on disk.** It lives in the login keychain; `openfortivpn` asks for it
  through `--pinentry=/usr/local/libexec/fvpn-pinentry`, an Assuan stub that answers the
  `<user>_<realm>_<host>_password` request from the keychain and refuses anything else (a
  token request must never be answered with the account password).
* **Root runs only root-owned code.** `/opt/homebrew` is owned by the admin user, so
  running the Homebrew binary as root through a `NOPASSWD` rule would be a privilege
  escalation. The setup copies `openfortivpn` + `libssl`/`libcrypto` into
  `/usr/local/libexec/fvpn`, rewrites the load commands to `@executable_path`/`@loader_path`,
  re-signs ad-hoc, and the helper refuses to run anything that is not root-owned or is
  group/world writable — including the parent directories and the config.
* **Config is checked, not trusted.** The helper also refuses a config whose `host` is not
  `<GATEWAY_PREFIX><name>.<GATEWAY_DOMAIN>`, because a tampered `host` would send the
  keychain password to another server.
* **Certificates are verified, then pinned.** The setup proves platform trust (chain +
  hostname) and re-checks the exact certificate it is about to pin with
  `security verify-cert`, then stores the SHA-256 as `trusted-cert`.
* **No persistent reconnect.** `--persistent` re-runs the login every few seconds whatever
  the reason, so a changed password would hammer the gateway into an account lockout. One
  attempt per `fvpn up`.

## Troubleshooting

| symptom | cause / fix |
| --- | --- |
| `ERROR: Could not authenticate` | password changed (`bash fvpn-setup.sh --reset-cred`), or the gateway wants a token you did not approve |
| tunnel does not come up, no push | the push was not approved within the wait budget, or the gateway fell back to OTP → `fvpn manual <gateway>` |
| `refuse: … not root-owned` / `group/world writable` | something replaced the pinned binary or the config — re-run `fvpn-setup.sh` |
| `missing config … (re-run setup)` | gateway not installed: add the profile in FortiClient and re-run the setup |
| tunnel stops working on a fixed date each year | the gateway certificate was renewed and the pinned digest no longer matches — re-run the setup |
| `ERROR: ppp0 already exists` | FortiClient (or another tunnel) is up: `fvpn down` first |
| notifications never appear | allow notifications for *Script Editor*, and check `~/Library/Logs/fvpn-watch.log` |

Logs: `/var/log/fvpn-<gateway>.log` (openfortivpn), `/var/log/fvpn-pinentry.log`
(which credential prompt arrived), `~/Library/Logs/fvpn-watch.log` (watcher).

## Adding a gateway

Add the profile in FortiClient, then re-run `bash fvpn-setup.sh` and check `fvpn list`.
Only SSL VPN profiles (`VpnType 0`) whose server matches
`<GATEWAY_PREFIX><name>.<GATEWAY_DOMAIN>` are picked up; IPsec profiles are ignored.

## Uninstall

```bash
launchctl bootout gui/$(id -u)/ai.fvpn.watch 2>/dev/null
rm -f ~/Library/LaunchAgents/ai.fvpn.watch.plist
sudo rm -f /etc/sudoers.d/fvpn /usr/local/bin/fvpn /usr/local/sbin/fvpn-root \
           /usr/local/libexec/fvpn-pinentry /var/log/fvpn-intent
sudo rm -rf /usr/local/libexec/fvpn /usr/local/etc/openfortivpn
security delete-generic-password -s "${KEYCHAIN_ITEM:-fvpn-vpn-password}"
```

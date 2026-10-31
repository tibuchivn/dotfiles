# SECURITY.md — fvpn tooling

Security properties, threat model, and known limitations of the `fvpn` tooling
(`fvpn-setup.sh`, `fvpn-root`, `fvpn-pinentry`, `fvpn`).

This document is intended for anyone reviewing or operating this tool. It
states what the design does and does not protect against, so that operators
do not over-trust it and reviewers do not have to reverse-engineer intent.

---

## 1. What this tool is

`fvpn-setup.sh` installs a one-time, unattended wrapper around
[openfortivpn](https://github.com/adrienverge/openfortivpn) so that a single
macOS user can bring up and tear down a FortiGate SSL VPN tunnel to the
configured corporate gateways without typing a password each time:

```
fvpn up <gw> [seconds]  |  fvpn down [<gw>]  |  fvpn status  |  fvpn list
fvpn manual <gw>        |  fvpn logs <gw> [lines]
```

Installed artefacts:

| Path | Purpose | Mode / owner |
|---|---|---|
| login keychain item `fvpn-vpn-password` | VPN password, ACL trusted to `/usr/bin/security` | per-user |
| `/usr/local/libexec/fvpn/` | pinned copy of `openfortivpn` + Homebrew dylibs | `755 root:wheel` |
| `/usr/local/libexec/fvpn-pinentry` | Assuan pinentry stub (keychain → openfortivpn) | `755 root:wheel` |
| `/usr/local/etc/openfortivpn/<gw>.conf` | host, port, user, pinned cert — **no password** | `600 root:wheel` |
| `/usr/local/sbin/fvpn-root` | root helper: `list`/`up`/`down`/`manual`/`status`/`logs` | `755 root:wheel` |
| `/usr/local/bin/fvpn` | user wrapper: `sudo -n fvpn-root "$@"` | `755 root:wheel` |
| `/etc/sudoers.d/fvpn` | `NOPASSWD` for `fvpn-root` only | `440 root:wheel` |

Tenant-specific values (`VPN_USER`, `GATEWAY_DOMAIN`, `GATEWAY_PREFIX`,
`KEYCHAIN_ITEM`, an optional fixed `FVPN_GATEWAYS` list, and the `DNS_PROBE`
address used by the watcher) come from `fvpn.local.sh` next to the script. That
file is **gitignored** — setup aborts with a clear message when it is missing —
and its values are substituted into the generated helper (`__PREFIX__`,
`__DOMAIN__`, `__ITEM__` placeholders) at install time, so the installed
artefacts stay tenant-specific while the tracked script does not.

A watcher is optional and runs as the ordinary user: `fvpn-watch.sh` plus
`ai.fvpn.watch.plist` post a local notification when an `fvpn up` request ends
up without a healthy tunnel. It reads `/var/log/fvpn-intent` (see §4.10) and it
never reconnects anything.

---

## 2. Threat model

### 2.1 Assets protected

1. **The VPN password.** Reused for a corporate account; compromise grants
   network access to internal corporate systems.
2. **Root on the local Mac.** Compromise is out of scope of the VPN, but the
   tool must not *create* a path from user-level code to root.
3. **The corporate VPN session.** A pinned certificate prevents a network
   attacker from impersonating a gateway and harvesting the password.

### 2.2 Adversaries considered

| Adversary | In scope? | Notes |
|---|---|---|
| Network attacker (MITM on the path to a gateway) during and after setup | **Yes** | Mitigated by platform trust + exact-hostname verification + certificate pinning. |
| Malicious code running as the *unprivileged* VPN user | **Partially** | Cannot become root (see §3.1). Can read the VPN password from the login keychain (see §4.1). |
| Malicious code running as *root* | No | Out of scope; root can do anything. |
| Malicious code running as the *same admin user* that ran setup | **Partially** | Same as "unprivileged user" for the purposes of this tool, except it may tamper with Homebrew, `~/.curlrc`, etc. — see §4.2, §4.3. |
| Compromised Homebrew package (before setup) | No | Setup trusts the binary it copies; it does not verify its provenance. |
| Compromised Homebrew package (after setup) | No | The pinned copy is independent; see §3.4. |
| Malicious MDM / system trust store | No | Out of scope; the tool relies on the system trust evaluation. |
| Physical attacker with the unlocked machine | No | Out of scope. |

### 2.3 Explicitly out of scope

- Protecting the VPN password from the user who owns the login keychain.
- Protecting against a malicious firmware / kernel / hypervisor.
- Protecting against compromise of the gateway hosts themselves.
- Protecting data sent over the tunnel (that is TLS's job, not this tool's).
- Availability / DoS: the tool fails closed and exits; it does not retry
  indefinitely.

---

## 3. Security guarantees

### 3.1 The `NOPASSWD` sudoers entry does not grant root

/etc/sudoers.d/fvpn grants `NOPASSWD` for exactly one binary,
`/usr/local/sbin/fvpn-root`, and applies `secure_path` and `env_reset` to it.
`fvpn-root`:

- Sets `PATH=/usr/bin:/bin:/usr/sbin:/sbin` (no user-writable directories).
- Calls every external command by absolute path.
- Refuses to run if `/usr/local`, `/usr/local/libexec`,
  `/usr/local/libexec/fvpn`, `/usr/local/sbin`, the pinned `openfortivpn`,
  the pinentry stub, or any config file is not root-owned or is group/world
  writable.
- Only executes `openfortivpn` and `fvpn-pinentry` from
  `/usr/local/libexec/fvpn/`, which is root-owned.

Consequently, replacing `/opt/homebrew/bin/openfortivpn` (which lives in a
user-writable directory) does **not** affect what runs as root.

### 3.2 The VPN password is never at rest in a file or argv

- Setup prompts `security add-generic-password -w`, so the password is typed
  straight into `security(1)'s own prompt; it never appears in this script's
  arguments, files, or terminal echo.
- Configs under `/usr/local/etc/openfortivpn/` contain no password.
- `fvpn-pinentry` reads the password from the login keychain at handshake
  time and percent-escapes it directly into the Assuan `D` response.
- The pinentry stub does not log the value; the self-tests only report the
  *shape* of the response (`D` present, count of `OK`), never the value.

### 3.3 Gateway impersonation is prevented by platform trust + exact hostname + pinning

For each configured gateway, setup:

1. Performs a `curl -q --noproxy '*' --proto '=https'` request to
   `https://<host>/remote/login`, which relies on the macOS platform trust
   evaluation (full chain, hostname, and AIA fetching of missing
   intermediates, which some gateways require).
2. Fetches the **exact leaf certificate** that will be pinned.
3. Runs `security verify-cert -q -p ssl -c "$pem" -n "$host"` on that leaf,
   proving it is trusted by the platform for **this exact hostname**. This
   closes the "curl-vs-openssl" gap where a MITM that fingerprints clients
   could hand `curl` a valid cert and `openssl s_client` a self-signed one.
4. Runs `openssl x509 -checkhost "$host"` to re-confirm SAN match
   (exact hostname, not a substring).
5. Refuses to pin if any check fails, or if the certificate expires within
   21 days (emits a warning instead of failing, so the operator can re-run
   after renewal).
6. Pins the SHA-256 fingerprint into the gateway config as
   `trusted-cert = ...`.

`openfortivpn` then refuses to connect if the presented certificate does not
match the pinned digest, so post-setup MITM is also blocked.

### 3.4 A Homebrew upgrade cannot change what runs as root

The pinned copy under `/usr/local/libexec/fvpn/` is independent of the
Homebrew keg. `brew upgrade openfortivpn` changes the brew binary but **not**
the root-owned copy. To adopt a new version, the operator must re-run
`fvpn-setup.sh` — which re-verifies gateway certificates from scratch.

### 3.5 The pinned copy is self-contained and self-checked

`build_pinned_copy`:

- Copies the brew `openfortivpn` and every Homebrew dylib it transitively
  needs into `/usr/local/libexec/fvpn/`.
- Rewrites all `/opt/homebrew/...` load commands to `@executable_path/...`
  and `@loader_path/...`.
- Ad-hoc re-signs every file (`codesign -f -s -`).
- Verifies `otool -L` no longer references any Homebrew path
  (`refs == 0`) and that the binary runs (`--version`) before installing.
- Refuses to install otherwise.

### 3.6 The environment is reset by sudo

sudoers applies `env_reset` to `fvpn-root`, and `fvpn-root` and
`fvpn-pinentry` both set `PATH` explicitly. Environment variables inherited
from the invoking shell (including `FVPN_OWNER`, `FVPN_KEYCHAIN_ITEM`,
`CURL_CA_BUNDLE`, `LD_*`, `DYLD_*`) do not affect the root-side code paths.

### 3.7 Logs are root-owned and not world-readable

`fvpn-root` runs with `umask 077`, pre-creates `/var/log/fvpn-<gw>.log` and
`chmod 600` s it before writing. Logs contain the gateway name, VPN username,
assigned IP, DNS and default route — no password, but still not public.

---

## 4. Known limitations and accepted risks

### 4.1 The VPN password is readable by any process running as the VPN user

The keychain item is created with `-T /usr/bin/security`, so that
`security(1)` can read it without an interactive unlock prompt during the
unattended handshake. The ACL is **not** restricted to a specific calling
binary; any process running as the owning user can run:

```bash
security find-generic-password -s fvpn-vpn-password -w
```

and obtain the password without a prompt, as long as the login keychain is
unlocked (i.e. the user is logged in). This is the price of unattended
operation. It is weaker than a `600 root:wheel` file (which only root could
read) but stronger than putting the password in a config file or in argv.

**If your threat model treats user-level malware as significant, do not use
this tool as-is.** Choose one of:

- Keep the password in a root-only file and read it directly from
  `fvpn-root` (unattended, but no keychain protection against root-level
  exfiltration), or
- Require the user to unlock the keychain item interactively per session
  (removes unattended operation).

### 4.2 Setup trusts the Homebrew `openfortivpn` binary as-is

`build_pinned_copy` copies whatever `/opt/homebrew/bin/openfortivpn` is
present. It does not verify a signature, a hash, or a version. If the brew
keg is compromised **before setup runs**, the pinned copy is compromised too.
Mitigation: run setup on a freshly-installed, trusted Homebrew.

### 4.3 Setup trusts the network on first run (TOFO, but scoped)

The first time setup runs, it trusts whatever certificate the system trust
evaluation accepts for each gateway. This is not a "first-use" pinning in the
weak sense — the certificate is verified against the platform trust store
(including AIA) — but it does mean that a **compromised CA** or a
**mis-issued certificate** at that moment would be pinned. If you have an
out-of-band fingerprint for the gateways, compare it against the digest
printed by setup before continuing.

### 4.4 `security verify-cert` relies on the macOS trust evaluation

The certificate-trust gate uses `security verify-cert`, which relies on the
system trust store, trust settings, and AIA fetching. On a machine where AIA
is disabled (some MDM profiles) or the AIA URL is unreachable, the
a gateway that sends only its leaf certificate may fail
verification even though `curl` succeeded. The tool fails closed in this
case; check `security verify-cert` (without `-q`) for the reason.

### 4.5 Some gateways omit intermediate certificates

Gateways that send only the leaf certificate rely on the client fetching the
missing intermediates through AIA: `curl` (via SecureTransport) does this
automatically. If the gateway configuration changes, re-run setup and inspect
the output; if the AIA URL becomes unreachable, the `security verify-cert`
step will fail.

### 4.6 `sudo` timestamp is used by the setup self-test

The step-7 self-test runs `sudo -n "$STUB"`; this only succeeds if a sudo
timestamp from the preceding setup commands is still valid. Setup normally
completes within that window, but a slow run (large Homebrew install, slow
network) can expire the timestamp and make the self-test fail with a
misleading message. Re-run setup, or run `sudo -v` before step 7.

### 4.7 Logs are not rotated

/var/log/fvpn-<gw>.log grows without bound. Rotate with newsyslog or a
launchd job if you care. This is an operational hygiene issue, not a
security one; the logs contain no secrets.

### 4.8 The tool does not enforce a split-tunnel / full-tunnel policy

`set-dns = 1` and `pppd-use-peerdns = 1` are set in the generated configs,
but the tool does not check whether the tunnel actually becomes the default
route, nor whether DNS resolves only through the tunnel. It reports the
observed state via `fvpn status`. Policy enforcement is out of scope.

### 4.9 The tool requires the caller to be an admin (for `sudo -v` during setup)

Setup needs `sudo` once. After installation, `fvpn up|down|status` requires
no password, but still requires the user to be permitted by
/etc/sudoers.d/fvpn. Removing the user from that file (or deleting it)
revokes the capability.

---

### 4.10 `/var/log/fvpn-intent` is world-readable

The root helper records the last request as `up <gateway> <epoch>` or
`down - <epoch>` in `/var/log/fvpn-intent` with mode `0644`, because the watcher
that reads it runs as the unprivileged user. It therefore reveals which gateway
was last requested and when, to any local user — but carries no credential. If
that is unacceptable, remove the file and skip the watcher; `fvpn` itself does
not depend on it.

---

## 5. Operational requirements

- **macOS only.** The script uses `security(1)`, `codesign(1)`,
  `install_name_tool(1)`, `otool(1)`, `ifconfig(8)`, `scutil(8)`,
  `netstat(1)`. It will not run on Linux.
- **Homebrew** with `openfortivpn` installed (`brew install openfortivpn`).
- **OpenSSL with `-checkhost`.** `brew install openssl@3 ` (or `@4`) — the
  system `/usr/bin/openssl` is LibreSSL and does not have `-checkhost`.
- **One-time `sudo`.** The user running setup must be an admin.
- **The user must remain logged in** for the login keychain to be unlocked
  and readable by the pinentry stub. Logging out and back in is fine; the
  keychain unlocks at login.

---

## 6. What to do if something looks wrong

### 6.1 If you suspect the keychain item has been read

Any process running as the VPN user can read it (see §4.1). If you suspect
compromise:

1. `fvpn down`.
2. Remove the item: `security delete-generic-password -s fvpn-vpn-password`.
3. Rotate the VPN password on the FortiGate side.
4. Re-run `fvpn-setup.sh` with the new password.

### 6.2 If you suspect the pinned copy has been tampered with

`fvpn-root` already refuses to run if the files are not root-owned or are
group/world-writable. For a stronger check:

```bash
sudo codesign -v /usr/local/libexec/fvpn/*
sudo otool -L /usr/local/libexec/fvpn/* | grep /opt/homebrew/   # expect no output
```

If either check fails, do not run `fvpn`; re-run `fvpn-setup.sh` from a
trusted environment.

### 6.3 If you suspect a gateway certificate has changed

Re-run `fvpn-setup.sh`. It re-verifies every configured gateway and re-pins. If a
gateway's new certificate does not pass platform trust + `-checkhost`, setup
aborts **before** touching the pinned configs. Old configs remain in place
until setup completes, so a failed setup leaves the previous, working pins
untouched.

### 6.4 If you need to uninstall

```bash
sudo rm -f /etc/sudoers.d/fvpn
sudo rm -f /usr/local/sbin/fvpn-root
sudo rm -f /usr/local/bin/fvpn
sudo rm -f /usr/local/libexec/fvpn-pinentry
sudo rm -rf /usr/local/libexec/fvpn
sudo rm -rf /usr/local/etc/openfortivpn
security delete-generic-password -s fvpn-vpn-password
```

Removing `/etc/sudoers.d/fvpn` revokes the `NOPASSWD` capability
immediately; the other files are inert without it.

---

## 7. Security-relevant changes since the initial version

The following defects were found in review and fixed. They are recorded here
so that future maintainers do not reintroduce them.

| # | Issue | Fix |
|---|---|---|
| 1 | `fvpn-root` executed `/opt/homebrew/bin/openfortivpn` (user-writable) as root through a `NOPASSWD` entry. Any user-level code could become root. | Copy the binary + dylibs to `/usr/local/libexec/fvpn/` (root-owned), rewrite load commands, re-sign, verify no `/opt/homebrew/` references remain. |
| 2 | `fvpn-root` and `fvpn-pinentry` used the inherited `PATH`, which put `/opt/homebrew/bin` first. | Fixed `PATH=/usr/bin:/bin:/usr/sbin:/sbin` in setup, `fvpn-root`, and `fvpn-pinentry`; every external command called by absolute path. |
| 3 | `fvpn-root` did not verify ownership / permissions of its own directories or binaries. | Added ownership + mode checks on `/usr/local`, `/usr/local/libexec`, `$OFP_DIR`, `$OFP`, `$PINENTRY`, and the config file. |
| 4 | Gateway verification used `openssl s_client` with a substring subject check (`*<corp-domain>*`); no chain verification. A MITM with any cert containing that substring could be pinned. | Platform trust via `curl` (AIA-capable) + `security verify-cert -c "$pem" -n "$host"` on the exact leaf + `openssl x509 -checkhost` + expiry check + exact digest length check. |
| 5 | `curl` could be influenced by `~/.curlrc`, `http_proxy`, and protocol downgrade. | `curl -q --noproxy '*' --proto '=https'`. |
| 6 | `fvpn-root` did not set `umask 077`; log could be world-readable. | `umask 077` + pre-create log + `chmod 600`. |
| 7 | On `up` timeout, the started `openfortivpn` was left running, holding `ppp0` and blocking subsequent `up`. | Capture `$ofp_pid`, kill on timeout, re-pgrep and kill any stragglers. |
| 8 | `for dep in $(otool -L ...) ` word-split on whitespace. | `while IFS= read -r` over `hb_deps()`. |
| 9 | `sed -i '' "s|__OWNER__|$ME|"` could be corrupted by `&` or `|` in the username. | `perl -pi -e 's/__OWNER__/$ENV{FVPN_OWNER}/g'` with the owner passed via environment. |
| 10 | Self-test only checked for a `D` line, not the full Assuan dialogue. | Test the full `SETTITLE/SETRESC/SETKEYINFO/SETPROMPT/GETPIN` sequence and require 5×`OK` + 1×`D`. |
| 11 | `fvpn-pinentry` was suspected of missing a trailing `OK` after `D`. | Verified against `openfortivpn`'s `src/userinput.c:pinentry_read`: it reads exactly one line per exchange and does not use libassuan. No `OK` is correct; adding one would write to a closed pipe. |

---

## 8. Reporting a vulnerability

If you find a security issue in this tooling, **do not open a public issue**.
Contact the maintainer of this repository directly (see `git log` for the
current maintainer) with:

- A description of the issue and its impact.
- Reproduction steps (a minimal proof-of-concept if possible).
- The version / commit you tested against.
- Whether you believe the issue is in this tooling or in a dependency
  (`openfortivpn`, Homebrew, macOS `security(1)`, etc.).

Please allow a reasonable window for a fix before public disclosure.

---

## 9. References

- `openfortivpn` upstream: <https://github.com/adrienverge/openfortivpn>
  - `src/userinput.c` — the pinentry protocol reader.
  - `--pinentry`, `--persistent`, `trusted-cert` documented in the man page.
- macOS `security(1)`: `man security`, `man security-verify-cert`.
- Assuan protocol: <https://www.gnupg.org/documentation/manuals/assuan/>
  (for context; `openfortivpn` does not use libassuan).
- `codesign(1)`, `install_name_tool(1)`, `otool(1)`: Apple developer
  documentation.

# Copy to fvpn.local.sh (same directory) and fill in. The real file is gitignored.
#
# Tenancy / identity -----------------------------------------------------------
# Account used to log in to the SSL VPN (as shown in FortiClient).
VPN_USER='CORP\your.username'

# Corporate DNS domain the gateways live under, and their hostname prefix:
# <prefix><gateway>.<domain>  ->  vpn-asia1.example.com
GATEWAY_DOMAIN='example.com'
GATEWAY_PREFIX='vpn-'

# Optional: fixed gateway list. Leave empty to discover the profiles from
# FortiClient's vpn.plist on every setup run.
FVPN_GATEWAYS=''

# Optional overrides -----------------------------------------------------------
# IP pinged by the watcher to tell "connected" from "connected but dead".
# Leave empty to skip that check.
DNS_PROBE=''

# Login keychain item holding the VPN password.
KEYCHAIN_ITEM='fvpn-vpn-password'

# Watcher tuning (fvpn-watch.sh) -----------------------------------------------
# Fallback window used when the intent file has no deadline field (older helper):
# seconds after `fvpn up` during which a down tunnel counts as "still authenticating".
UP_GRACE=180

# 1 = also banner an `fvpn up` that never produced a tunnel. Default 0: silent,
# because `fvpn up` already printed the error and nothing was lost.
UP_FAIL_NOTIFY=0

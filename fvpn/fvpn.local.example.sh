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

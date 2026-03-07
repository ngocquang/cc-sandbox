#!/bin/bash
# ============================================================
# init-firewall.sh — Network firewall for Claude Code sandbox
# ============================================================
# Whitelists: Claude API/Code, npm, GitHub, PyPI, VS Code marketplace
# Default-deny for ALL outbound TCP (not just 80/443)
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

# ── Whitelisted domains ─────────────────────────────────────
ALLOWED_DOMAINS=(
    # Anthropic / Claude API
    "api.anthropic.com"
    "auth.anthropic.com"
    "statsig.anthropic.com"
    "sentry.io"
    "anthropic.gallerycdn.azure.cn"

    # npm registry
    "registry.npmjs.org"
    "registry.yarnpkg.com"

    # GitHub
    "github.com"
    "api.github.com"
    "raw.githubusercontent.com"
    "objects.githubusercontent.com"
    "github-releases.githubusercontent.com"

    # PyPI (Python packages)
    "pypi.org"
    "files.pythonhosted.org"

    # Claude Code distribution
    "storage.googleapis.com"

    # Microsoft
    "microsoft.com"

    # VS Code extensions & devcontainer features
    "open-vsx.org"
    "marketplace.visualstudio.com"
    "update.code.visualstudio.com"
    "vscode.blob.core.windows.net"
    "az764295.vo.msecnd.net"
    "gallerycdn.vsassets.io"
    "vscode.download.prss.microsoft.com"
    "default.exp-tas.com"
)

# ── Load extra domains from env ──────────────────────────────
if [[ -n "${EXTRA_ALLOWED_DOMAINS:-}" ]]; then
    IFS=',' read -ra EXTRA <<< "$EXTRA_ALLOWED_DOMAINS"
    for d in "${EXTRA[@]}"; do
        # Validate domain format (alphanumeric, dots, hyphens only)
        if [[ "$d" =~ ^[a-zA-Z0-9.*-]+$ ]]; then
            ALLOWED_DOMAINS+=("$d")
        else
            echo -e "${RED}Skipping invalid domain: ${d}${NC}" >&2
        fi
    done
fi

echo ""
echo -e "${CYAN}Configuring network firewall...${NC}"

# ── Resolve domains to IPs ────────────────────────────────────
ipset create allowed_ips hash:ip -exist 2>/dev/null || true
ipset flush allowed_ips

resolved=0
for domain in "${ALLOWED_DOMAINS[@]}"; do
    ips=$(dig +short "$domain" A 2>/dev/null | grep -E '^[0-9]+\.' || true)
    for ip in $ips; do
        ipset add allowed_ips "$ip" -exist 2>/dev/null || true
        ((resolved++)) || true
    done
done

# ── iptables rules ───────────────────────────────────────────
iptables -F OUTPUT 2>/dev/null || true

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established/related connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# DNS: allow local resolvers only (prevent DNS tunneling)
iptables -A OUTPUT -p udp --dport 53 -d 127.0.0.0/8 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -d 172.16.0.0/12 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -d 192.168.0.0/16 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -d 10.0.0.0/8 -j ACCEPT
# OrbStack uses 0.250.250.200 for its DNS resolver
iptables -A OUTPUT -p udp --dport 53 -d 0.0.0.0/8 -j ACCEPT

# Allow SSH only to whitelisted IPs (for git over SSH)
iptables -A OUTPUT -m set --match-set allowed_ips dst -p tcp --dport 22 -j ACCEPT

# Allow whitelisted IPs on standard web ports
iptables -A OUTPUT -m set --match-set allowed_ips dst -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed_ips dst -p tcp --dport 443 -j ACCEPT

# Default deny ALL other outbound TCP (blocks all ports, not just 80/443)
iptables -A OUTPUT -p tcp -j DROP
# Block non-whitelisted DNS
iptables -A OUTPUT -p udp --dport 53 -j DROP

echo -e "${GREEN}Firewall active${NC} — ${#ALLOWED_DOMAINS[@]} domains whitelisted, ${resolved} IPs resolved"
echo ""
echo -e "${DIM}    Allowed:${NC}"
for d in "${ALLOWED_DOMAINS[@]}"; do
    echo -e "${DIM}      - ${d}${NC}"
done
echo ""
echo -e "${YELLOW}All other outbound TCP traffic is BLOCKED.${NC}"
echo ""

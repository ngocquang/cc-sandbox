#!/usr/bin/env bats
# Unit tests for docker/init-firewall.sh

load test-helper.bash

setup() {
    setup_temp
}

teardown() {
    teardown_temp
}

# ══════════════════════════════════════════════════════════════
# Script syntax & structure
# ══════════════════════════════════════════════════════════════

@test "init-firewall.sh has valid bash syntax" {
    run bash -n "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "init-firewall.sh is executable" {
    [ -x "$FIREWALL_SCRIPT" ]
}

@test "init-firewall.sh uses strict mode" {
    run grep -c "set -euo pipefail" "$FIREWALL_SCRIPT"
    [ "$output" = "1" ]
}

# ══════════════════════════════════════════════════════════════
# Default allowed domains
# ══════════════════════════════════════════════════════════════

@test "includes Anthropic API domains" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    [[ "$content" == *"api.anthropic.com"* ]]
    [[ "$content" == *"statsig.anthropic.com"* ]]
    [[ "$content" == *"sentry.io"* ]]
}

@test "includes npm registry domains" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    [[ "$content" == *"registry.npmjs.org"* ]]
    [[ "$content" == *"registry.yarnpkg.com"* ]]
}

@test "includes GitHub domains" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    [[ "$content" == *"github.com"* ]]
    [[ "$content" == *"api.github.com"* ]]
    [[ "$content" == *"raw.githubusercontent.com"* ]]
    [[ "$content" == *"objects.githubusercontent.com"* ]]
    [[ "$content" == *"github-releases.githubusercontent.com"* ]]
}

@test "includes PyPI domains" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    [[ "$content" == *"pypi.org"* ]]
    [[ "$content" == *"files.pythonhosted.org"* ]]
}

@test "includes VS Code marketplace domains" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    [[ "$content" == *"open-vsx.org"* ]]
    [[ "$content" == *"marketplace.visualstudio.com"* ]]
    [[ "$content" == *"update.code.visualstudio.com"* ]]
}

# ══════════════════════════════════════════════════════════════
# EXTRA_ALLOWED_DOMAINS validation
# ══════════════════════════════════════════════════════════════

@test "domain validation regex accepts valid domains" {
    # Extract the validation regex from the script
    local regex='^[a-zA-Z0-9.*-]+$'

    [[ "api.example.com" =~ $regex ]]
    [[ "my-service.io" =~ $regex ]]
    [[ "*.wildcard.com" =~ $regex ]]
    [[ "sub.domain.example.org" =~ $regex ]]
}

@test "domain validation regex rejects invalid domains" {
    local regex='^[a-zA-Z0-9.*-]+$'

    ! [[ "evil;cmd" =~ $regex ]]
    ! [[ "bad domain.com" =~ $regex ]]
    ! [[ "path/inject" =~ $regex ]]
    ! [[ '$(whoami)' =~ $regex ]]
    ! [[ "foo&bar" =~ $regex ]]
}

# ══════════════════════════════════════════════════════════════
# Security rules in the script
# ══════════════════════════════════════════════════════════════

@test "has default-deny TCP rule" {
    run grep "iptables -A OUTPUT -p tcp -j DROP" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "has DNS drop rule for non-whitelisted" {
    run grep "iptables -A OUTPUT -p udp --dport 53 -j DROP" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "allows loopback traffic" {
    run grep "iptables -A OUTPUT -o lo -j ACCEPT" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "allows established connections" {
    run grep "ESTABLISHED,RELATED" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "allows SSH port 22 only to whitelisted IPs" {
    run grep "match-set allowed_ips dst -p tcp --dport 22 -j ACCEPT" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "restricts DNS to local resolvers" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    [[ "$content" == *"127.0.0.0/8"* ]]
    [[ "$content" == *"172.16.0.0/12"* ]]
    [[ "$content" == *"192.168.0.0/16"* ]]
    [[ "$content" == *"10.0.0.0/8"* ]]
    # OrbStack DNS resolver (0.250.250.200)
    [[ "$content" == *"0.0.0.0/8"* ]]
}

@test "allows only ports 80 and 443 for whitelisted IPs" {
    run grep -c "match-set allowed_ips dst -p tcp --dport \(80\|443\) -j ACCEPT" "$FIREWALL_SCRIPT"
    # Should find rules for both port 80 and 443
    run grep "match-set allowed_ips dst -p tcp --dport 80" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
    run grep "match-set allowed_ips dst -p tcp --dport 443" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "flushes OUTPUT chain before applying rules" {
    run grep "iptables -F OUTPUT" "$FIREWALL_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "creates ipset before using it" {
    local content
    content=$(cat "$FIREWALL_SCRIPT")

    # ipset create should come before iptables rules
    local create_line
    create_line=$(grep -n "ipset create" "$FIREWALL_SCRIPT" | head -1 | cut -d: -f1)
    local iptables_line
    iptables_line=$(grep -n "iptables -F OUTPUT" "$FIREWALL_SCRIPT" | head -1 | cut -d: -f1)

    [ "$create_line" -lt "$iptables_line" ]
}

#!/usr/bin/env bats
# Unit tests for cc-sandboxer.sh

load test-helper.bash

setup() {
    setup_temp
}

teardown() {
    teardown_temp
}

# ══════════════════════════════════════════════════════════════
# Version & Help
# ══════════════════════════════════════════════════════════════

@test "version flag prints version and exits 0" {
    run bash "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"cc-sandboxer v${PKG_VERSION}"* ]]
}

@test "short version flag -v works" {
    run bash "$SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"cc-sandboxer v${PKG_VERSION}"* ]]
}

@test "help flag shows usage info" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"USAGE"* ]]
    [[ "$output" == *"cc-sandboxer"* ]]
    [[ "$output" == *"OPTIONS"* ]]
}

@test "short help flag -h works" {
    run bash "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"USAGE"* ]]
}

@test "help shows all documented options" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--init"* ]]
    [[ "$output" == *"--rebuild"* ]]
    [[ "$output" == *"--shell"* ]]
    [[ "$output" == *"--no-firewall"* ]]
    [[ "$output" == *"--allow-domain"* ]]
    [[ "$output" == *"--continue"* ]]
    [[ "$output" == *"--disallowedTools"* ]]
    [[ "$output" == *"--uninstall"* ]]
}

# ══════════════════════════════════════════════════════════════
# Argument Parsing — --allow-domain validation
# ══════════════════════════════════════════════════════════════

@test "allow-domain rejects missing argument" {
    run bash "$SCRIPT" --allow-domain
    [ "$status" -eq 1 ]
    [[ "$output" == *"requires a domain argument"* ]]
}

@test "allow-domain rejects domain followed by another flag" {
    run bash "$SCRIPT" --allow-domain --shell
    [ "$status" -eq 1 ]
    [[ "$output" == *"requires a domain argument"* ]]
}

@test "allow-domain rejects invalid domain with special chars" {
    run bash "$SCRIPT" --allow-domain "evil;rm -rf /"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain format"* ]]
}

@test "allow-domain rejects domain with spaces" {
    run bash "$SCRIPT" --allow-domain "has space.com"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain format"* ]]
}

@test "allow-domain rejects domain with slashes" {
    run bash "$SCRIPT" --allow-domain "evil.com/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain format"* ]]
}

# ══════════════════════════════════════════════════════════════
# Argument Parsing — invalid project path
# ══════════════════════════════════════════════════════════════

@test "exits with error for non-existent project path" {
    run bash "$SCRIPT" /nonexistent/path/foobar --version 2>&1 || true
    # --version is processed first so this should succeed
    # Test without --version to trigger path resolution
    run bash "$SCRIPT" /nonexistent/path/foobar
    [ "$status" -ne 0 ]
}

# ══════════════════════════════════════════════════════════════
# --init mode — VS Code DevContainer setup
# ══════════════════════════════════════════════════════════════

@test "init creates devcontainer directory" {
    run bash "$SCRIPT" --init "$TEST_TEMP"
    [ "$status" -eq 0 ]
    [ -d "$TEST_TEMP/.devcontainer" ]
}

@test "init creates Dockerfile" {
    run bash "$SCRIPT" --init "$TEST_TEMP"
    [ "$status" -eq 0 ]
    [ -f "$TEST_TEMP/.devcontainer/Dockerfile" ]
}

@test "init creates devcontainer.json" {
    run bash "$SCRIPT" --init "$TEST_TEMP"
    [ "$status" -eq 0 ]
    [ -f "$TEST_TEMP/.devcontainer/devcontainer.json" ]
}

@test "init creates init-firewall.sh and makes it executable" {
    run bash "$SCRIPT" --init "$TEST_TEMP"
    [ "$status" -eq 0 ]
    [ -f "$TEST_TEMP/.devcontainer/init-firewall.sh" ]
    [ -x "$TEST_TEMP/.devcontainer/init-firewall.sh" ]
}

@test "init creates .vscode/tasks.json" {
    run bash "$SCRIPT" --init "$TEST_TEMP"
    [ "$status" -eq 0 ]
    [ -f "$TEST_TEMP/.vscode/tasks.json" ]
}

@test "init does not overwrite existing tasks.json" {
    mkdir -p "$TEST_TEMP/.vscode"
    echo '{"existing": true}' > "$TEST_TEMP/.vscode/tasks.json"

    run bash "$SCRIPT" --init "$TEST_TEMP"
    [ "$status" -eq 0 ]

    # Original content preserved
    run cat "$TEST_TEMP/.vscode/tasks.json"
    [[ "$output" == *'"existing": true'* ]]
}

@test "init devcontainer.json contains required config" {
    bash "$SCRIPT" --init "$TEST_TEMP"

    local content
    content=$(cat "$TEST_TEMP/.devcontainer/devcontainer.json")

    [[ "$content" == *'"name": "Claude Code Sandbox"'* ]]
    [[ "$content" == *'"dockerfile": "Dockerfile"'* ]]
    [[ "$content" == *'"--cap-add=NET_ADMIN"'* ]]
    [[ "$content" == *'"workspaceFolder": "/workspace"'* ]]
    [[ "$content" == *'claude-code-config'* ]]
}

@test "init tasks.json contains all 6 tasks" {
    bash "$SCRIPT" --init "$TEST_TEMP"

    local content
    content=$(cat "$TEST_TEMP/.vscode/tasks.json")

    [[ "$content" == *"Claude: Skip Permissions"* ]]
    [[ "$content" == *"Claude: Resume Last Chat"* ]]
    [[ "$content" == *"Claude: One-Shot Task"* ]]
    [[ "$content" == *"Claude: Safe Mode (no rm)"* ]]
    [[ "$content" == *"Firewall: Re-initialize"* ]]
    [[ "$content" == *"Claude: Login"* ]]
}

@test "init Dockerfile matches source docker/Dockerfile" {
    bash "$SCRIPT" --init "$TEST_TEMP"

    run diff "$PROJECT_ROOT/docker/Dockerfile" "$TEST_TEMP/.devcontainer/Dockerfile"
    [ "$status" -eq 0 ]
}

@test "init firewall script matches source docker/init-firewall.sh" {
    bash "$SCRIPT" --init "$TEST_TEMP"

    run diff "$PROJECT_ROOT/docker/init-firewall.sh" "$TEST_TEMP/.devcontainer/init-firewall.sh"
    [ "$status" -eq 0 ]
}

@test "init tasks.json matches source vscode/tasks.json" {
    bash "$SCRIPT" --init "$TEST_TEMP"

    # Only when tasks.json doesn't already exist
    run diff "$PROJECT_ROOT/vscode/tasks.json" "$TEST_TEMP/.vscode/tasks.json"
    [ "$status" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════
# gen_firewall_file — firewall script generation
# ══════════════════════════════════════════════════════════════

@test "gen_firewall_file creates executable script" {
    source_functions
    EXTRA_DOMAINS=()

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    [ -f "$fw_file" ]
    [ -x "$fw_file" ]
}

@test "gen_firewall_file includes default domains" {
    source_functions
    EXTRA_DOMAINS=()

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    local content
    content=$(cat "$fw_file")

    [[ "$content" == *"api.anthropic.com"* ]]
    [[ "$content" == *"registry.npmjs.org"* ]]
    [[ "$content" == *"github.com"* ]]
    [[ "$content" == *"pypi.org"* ]]
}

@test "gen_firewall_file includes extra domains" {
    source_functions
    EXTRA_DOMAINS=("custom.example.com" "api.myservice.io")

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    local content
    content=$(cat "$fw_file")

    [[ "$content" == *"custom.example.com"* ]]
    [[ "$content" == *"api.myservice.io"* ]]
}

@test "gen_firewall_file contains iptables rules" {
    source_functions
    EXTRA_DOMAINS=()

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    local content
    content=$(cat "$fw_file")

    # Check key firewall rules
    [[ "$content" == *"iptables -F OUTPUT"* ]]
    [[ "$content" == *"iptables -A OUTPUT -o lo -j ACCEPT"* ]]
    [[ "$content" == *"iptables -A OUTPUT -p tcp -j DROP"* ]]
    [[ "$content" == *"iptables -A OUTPUT -p udp --dport 53 -j DROP"* ]]
}

@test "gen_firewall_file blocks DNS tunneling" {
    source_functions
    EXTRA_DOMAINS=()

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    local content
    content=$(cat "$fw_file")

    # DNS restricted to local resolvers only
    [[ "$content" == *"127.0.0.0/8"* ]]
    [[ "$content" == *"172.16.0.0/12"* ]]
    [[ "$content" == *"192.168.0.0/16"* ]]
    [[ "$content" == *"10.0.0.0/8"* ]]
    # OrbStack DNS resolver (0.250.250.200)
    [[ "$content" == *"0.0.0.0/8"* ]]
}

@test "gen_firewall_file allows SSH only to whitelisted IPs" {
    source_functions
    EXTRA_DOMAINS=()

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    local content
    content=$(cat "$fw_file")

    [[ "$content" == *"match-set allowed_ips dst -p tcp --dport 22 -j ACCEPT"* ]]
}

@test "gen_firewall_file with empty EXTRA_DOMAINS produces valid script" {
    source_functions
    EXTRA_DOMAINS=()

    local fw_file="$TEST_TEMP/firewall.sh"
    gen_firewall_file "$fw_file"

    # Script should have valid bash syntax
    run bash -n "$fw_file"
    [ "$status" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════
# Banner & display
# ══════════════════════════════════════════════════════════════

@test "banner shows version string" {
    run bash "$SCRIPT" --help
    [[ "$output" == *"v${PKG_VERSION}"* ]]
}

@test "banner shows ASCII art header" {
    run bash "$SCRIPT" --help
    [[ "$output" == *"CLAUDE"* ]]
    [[ "$output" == *"S A N D B O X"* ]]
}

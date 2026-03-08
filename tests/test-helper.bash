#!/usr/bin/env bash
# test-helper.bash — shared setup for bats tests

export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPT="${PROJECT_ROOT}/cc-sandboxer.sh"
export FIREWALL_SCRIPT="${PROJECT_ROOT}/docker/init-firewall.sh"
export PKG_VERSION=$(grep -o '"version": *"[^"]*"' "${PROJECT_ROOT}/package.json" 2>/dev/null | head -1 | grep -o '[0-9][0-9.]*' || echo "0.0.0")

# Create temp directory for each test
setup_temp() {
    TEST_TEMP="$(mktemp -d)"
}

# Cleanup temp directory
teardown_temp() {
    [[ -d "${TEST_TEMP:-}" ]] && rm -rf "$TEST_TEMP"
}

# Source only the functions from cc-sandboxer.sh without executing main
# by extracting function definitions
source_functions() {
    # Set SCRIPT_DIR so gen_firewall_file can find docker/init-firewall.sh
    SCRIPT_DIR="$PROJECT_ROOT"

    # Extract color/icon vars and function definitions, skip main execution
    eval "$(sed -n '
        /^# ── Colors/,/^# ── Logging/p
        /^# ── Emoji/,/^# ── Logging/p
        /^# ── Logging/,/^# ── Banner/p
    ' "$SCRIPT")"

    # Source specific functions by extracting them
    eval "$(sed -n '/^show_progress_line()/,/^}/p' "$SCRIPT")"
    eval "$(sed -n '/^gen_firewall_file()/,/^}$/p' "$SCRIPT")"
}

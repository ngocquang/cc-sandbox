#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  🧠 Claude Code Sandbox                                         ║
# ║  Run claude --dangerously-skip-permissions safely in Docker     ║
# ║  Works with Docker Desktop, OrbStack, Colima & VS Code         ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Config ───────────────────────────────────────────────────
IMAGE_NAME="cc-sandboxer"
IMAGE_TAG="latest"
CONTAINER_NAME="cc-sandboxer"
TZ="${TZ:-Asia/Ho_Chi_Minh}"
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"

# ── Version (read from package.json) ─────────────────────────
SCRIPT_VERSION=$(grep -o '"version": *"[^"]*"' "${SCRIPT_DIR}/package.json" 2>/dev/null | head -1 | grep -o '[0-9][0-9.]*' || echo "0.0.0")

# ── Detect install method (npx / global npm / git clone) ─────
detect_cmd_prefix() {
    if [[ -n "${npm_execpath:-}" && "${npm_lifecycle_event:-}" == "npx" ]] \
       || [[ "${SCRIPT_DIR}" == *"/_npx/"* ]] \
       || [[ "${SCRIPT_DIR}" == *"/.npm/_npx"* ]]; then
        echo "npx cc-sandboxer"
    elif [[ "${SCRIPT_DIR}" == *"/node_modules/.bin"* ]] \
         || command -v cc-sandboxer &>/dev/null; then
        echo "cc-sandboxer"
    else
        echo "./cc-sandboxer.sh"
    fi
}
CMD_PREFIX="$(detect_cmd_prefix)"

# ── Colors & Styles ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m'

# ── Emoji icons ──────────────────────────────────────────────
I_ROCKET="🚀"
I_BRAIN="🧠"
I_SHIELD="🛡️"
I_LOCK="🔒"
I_CHECK="✅"
I_CROSS="❌"
I_WARN="⚠️"
I_INFO="💡"
I_FOLDER="📁"
I_DOCKER="🐳"
I_GEAR="⚙️"
I_KEY="🔑"
I_GLOBE="🌐"
I_CLOCK="⏱️"
I_PACKAGE="📦"
I_SHELL="🐚"
I_SPARKLE="✨"
I_LINK="🔗"
I_ZAP="⚡"
I_PLUG="🔌"
I_VSCODE="💻"

# ── Logging ──────────────────────────────────────────────────
log()     { echo -e "  ${GREEN}${I_CHECK}${NC}  $*"; }
err()     { echo -e "  ${RED}${I_CROSS}${NC}  ${RED}$*${NC}" >&2; }
step()    { echo -e "  ${MAGENTA}${I_GEAR}${NC}  ${BOLD}$*${NC}"; }
success() { echo -e "  ${GREEN}${I_SPARKLE}${NC} ${GREEN}${BOLD}$*${NC}"; }

divider() {
    echo -e "  ${DIM}─────────────────────────────────────────────────────────${NC}"
}

# ── Update check (non-blocking) ──────────────────────────────
UPDATE_CHECK_FILE=""

check_update_background() {
    UPDATE_CHECK_FILE=$(mktemp /tmp/cc-sandboxer-update-XXXXXXXX)
    (
        local latest
        latest=$(curl -sf --max-time 3 "https://registry.npmjs.org/cc-sandboxer/latest" 2>/dev/null \
            | grep -o '"version":"[^"]*"' | head -1 | grep -o '[0-9][0-9.]*') || true
        if [[ -n "$latest" && "$latest" != "$SCRIPT_VERSION" ]]; then
            # Compare versions: check if latest is newer
            local IFS='.'
            read -ra current_parts <<< "$SCRIPT_VERSION"
            read -ra latest_parts <<< "$latest"
            local i is_newer=false
            for i in 0 1 2; do
                local c="${current_parts[$i]:-0}"
                local l="${latest_parts[$i]:-0}"
                if (( l > c )); then
                    is_newer=true; break
                elif (( l < c )); then
                    break
                fi
            done
            if [[ "$is_newer" == "true" ]]; then
                echo "$latest" > "$UPDATE_CHECK_FILE"
            fi
        fi
    ) &>/dev/null &
}

show_update_notice() {
    if [[ -n "${UPDATE_CHECK_FILE:-}" && -s "$UPDATE_CHECK_FILE" ]]; then
        local latest
        latest=$(cat "$UPDATE_CHECK_FILE")
        echo ""
        echo -e "  ${YELLOW}${I_WARN}  ${BOLD}Update available!${NC} ${DIM}v${SCRIPT_VERSION}${NC} → ${GREEN}${BOLD}v${latest}${NC}"
        echo -e "     ${DIM}Run${NC} ${GREEN}\"${CMD_PREFIX} --update\"${NC} ${DIM}to update${NC}"
    fi
    [[ -f "${UPDATE_CHECK_FILE:-}" ]] && rm -f "$UPDATE_CHECK_FILE"
}

# ── Banner ───────────────────────────────────────────────────
show_banner() {
    echo ""
    echo -e "${BOLD}${CYAN}"
    cat << 'BANNER'
       ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
      ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
      ██║     ██║     ███████║██║   ██║██║  ██║█████╗  
      ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  
      ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
       ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
BANNER
    echo -e "${NC}"
    echo -e "      ${BOLD}${WHITE}C O D E   S A N D B O X${NC}  ${DIM}v${SCRIPT_VERSION}${NC}"
    echo -e "      ${DIM}Run skip-permissions safely in a sandbox${NC}"
    echo ""
    divider
    echo ""
}

# ── Help ─────────────────────────────────────────────────────
show_help() {
    show_banner
    echo -e "  ${BOLD}${WHITE}USAGE${NC}"
    echo ""
    echo -e "    ${GREEN}${CMD_PREFIX}${NC} ${DIM}[project_path]${NC} ${DIM}[options]${NC}"
    echo ""
    echo -e "  ${BOLD}${WHITE}MODES${NC}"
    echo ""
    echo -e "    ${I_ROCKET} ${BOLD}CLI Mode${NC} ${DIM}(default)${NC} — Run directly from terminal"
    echo -e "    ${I_VSCODE} ${BOLD}VS Code Mode${NC}        — Use ${GREEN}--init${NC} to setup DevContainer"
    echo ""
    echo -e "  ${BOLD}${WHITE}ARGUMENTS${NC}"
    echo ""
    echo -e "    ${WHITE}project_path${NC}              Path to project ${DIM}(default: current directory)${NC}"
    echo ""
    echo -e "  ${BOLD}${WHITE}OPTIONS — Setup${NC}"
    echo ""
    echo -e "    ${GREEN}--init${NC}                    ${I_VSCODE} Setup devcontainer + VS Code tasks in project"
    echo -e "    ${GREEN}--rebuild${NC}                 ${I_PACKAGE} Force rebuild Docker image"
    echo -e "    ${GREEN}--update${NC}                   ${I_PACKAGE} Update to latest version & rebuild image"
    echo -e "    ${GREEN}--uninstall${NC}                ${I_CROSS} Remove image, volumes & cache"
    echo -e "    ${GREEN}--version${NC}, ${GREEN}-v${NC}             ${I_INFO} Show version"
    echo -e "    ${GREEN}--help${NC}, ${GREEN}-h${NC}                ${I_INFO} Show this help"
    echo ""
    echo -e "  ${BOLD}${WHITE}OPTIONS — Runtime${NC}"
    echo ""
    echo -e "    ${GREEN}--shell${NC}                   ${I_SHELL} Open shell only (don't start Claude)"
    echo -e "    ${GREEN}--no-firewall${NC}             ${I_GLOBE} Skip firewall setup"
    echo -e "    ${GREEN}--allow-domain${NC} ${DIM}NAME${NC}       ${I_PLUG} Whitelist extra domain ${DIM}(repeatable)${NC}"
    echo -e "    ${GREEN}--continue${NC}, ${GREEN}-c${NC}            ${I_LINK} Resume previous conversation"
    echo -e "    ${GREEN}-p${NC} ${DIM}\"prompt\"${NC}               ${I_ZAP} One-shot task mode"
    echo -e "    ${GREEN}--disallowedTools${NC} ${DIM}T${NC}        ${I_SHIELD} Block specific tools"
    echo ""
    echo -e "  ${BOLD}${WHITE}EXAMPLES${NC}"
    echo ""
    echo -e "    ${DIM}# Quick start — interactive mode${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX}"
    echo ""
    echo -e "    ${DIM}# Setup VS Code DevContainer in your project${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} --init ~/projects/my-app"
    echo ""
    echo -e "    ${DIM}# One-shot task${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} . -p \"Refactor auth and write tests\""
    echo ""
    echo -e "    ${DIM}# Resume last conversation${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} . --continue"
    echo ""
    echo -e "    ${DIM}# Safe mode — block rm commands${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} . --disallowedTools \"Bash(rm:*)\""
    echo ""
    echo -e "  ${BOLD}${WHITE}ENVIRONMENT${NC}"
    echo ""
    echo -e "    ${WHITE}TZ${NC}                        Timezone ${DIM}(default: Asia/Ho_Chi_Minh)${NC}"
    echo ""
    divider
    echo ""
}

# ══════════════════════════════════════════════════════════════
# 💻 VS Code Integration — --init command
# ══════════════════════════════════════════════════════════════

init_vscode_project() {
    local target_path="$1"

    show_banner
    step "Setting up VS Code DevContainer ${I_VSCODE}"
    echo ""
    echo -e "    ${DIM}Target:${NC} ${WHITE}${target_path}${NC}"
    echo ""

    # ── Create .devcontainer/ ───────────────────────────────
    local dc_dir="${target_path}/.devcontainer"
    mkdir -p "$dc_dir"

    # Dockerfile — copy from the project's single source of truth
    if [[ ! -f "${dc_dir}/Dockerfile" ]]; then
        cp "${SCRIPT_DIR}/docker/Dockerfile" "${dc_dir}/Dockerfile"
        show_progress_line "Created .devcontainer/Dockerfile" "done"
    else
        show_progress_line "Skipped .devcontainer/Dockerfile (already exists)" "skip"
    fi

    # Firewall script — copy from the project's init-firewall.sh
    if [[ ! -f "${dc_dir}/init-firewall.sh" ]]; then
        cp "${SCRIPT_DIR}/docker/init-firewall.sh" "${dc_dir}/init-firewall.sh"
        chmod +x "${dc_dir}/init-firewall.sh"
        show_progress_line "Created .devcontainer/init-firewall.sh" "done"
    else
        show_progress_line "Skipped .devcontainer/init-firewall.sh (already exists)" "skip"
    fi

    # devcontainer.json — copy from the project's single source of truth
    if [[ ! -f "${dc_dir}/devcontainer.json" ]]; then
        cp "${SCRIPT_DIR}/devcontainer/devcontainer.json" "${dc_dir}/devcontainer.json"
        # Fix Dockerfile path: in target project, Dockerfile is local to devcontainer/
        sed -i.bak 's|"dockerfile": "\.\./docker/Dockerfile"|"dockerfile": "Dockerfile"|' "${dc_dir}/devcontainer.json"
        sed -i.bak '/"context": "\.\.",/d' "${dc_dir}/devcontainer.json"
        rm -f "${dc_dir}/devcontainer.json.bak"
        show_progress_line "Created .devcontainer/devcontainer.json" "done"
    else
        show_progress_line "Skipped .devcontainer/devcontainer.json (already exists)" "skip"
    fi

    # ── Create .vscode/tasks.json ────────────────────────────
    local vscode_dir="${target_path}/.vscode"
    mkdir -p "$vscode_dir"

    # Only write tasks.json if it doesn't exist (don't clobber user's tasks)
    if [[ ! -f "${vscode_dir}/tasks.json" ]]; then
        cp "${SCRIPT_DIR}/vscode/tasks.json" "${vscode_dir}/tasks.json"
        show_progress_line "Created .vscode/tasks.json" "done"
    else
        show_progress_line "Skipped .vscode/tasks.json (already exists)" "skip"
    fi


    # ── Summary ──────────────────────────────────────────────
    echo ""
    divider
    echo ""
    success "VS Code DevContainer setup complete! ${I_SPARKLE}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Files created:${NC}"
    echo ""
    echo -e "    ${DIM}${target_path}/${NC}"
    echo -e "    ${DIM}├── ${NC}${WHITE}.devcontainer/${NC}"
    echo -e "    ${DIM}│   ├── ${NC}${CYAN}Dockerfile${NC}"
    echo -e "    ${DIM}│   ├── ${NC}${CYAN}devcontainer.json${NC}"
    echo -e "    ${DIM}│   └── ${NC}${CYAN}init-firewall.sh${NC}"
    echo -e "    ${DIM}└── ${NC}${WHITE}.vscode/${NC}"
    echo -e "    ${DIM}    └── ${NC}${CYAN}tasks.json${NC}"
    echo ""
    divider
    echo ""
    echo -e "  ${BOLD}${WHITE}Next steps:${NC}"
    echo ""
    echo -e "  ${I_VSCODE} ${BOLD}${WHITE}VS Code:${NC}"
    echo ""
    echo -e "    ${YELLOW}1.${NC}  Open the project in VS Code"
    echo -e "        ${GREEN}\$${NC} code ${target_path}"
    echo ""
    echo -e "    ${YELLOW}2.${NC}  Reopen in Container"
    echo -e "        ${DIM}Cmd+Shift+P → \"Dev Containers: Reopen in Container\"${NC}"
    echo ""
    echo -e "    ${YELLOW}3.${NC}  Login (first time only)"
    echo -e "        ${DIM}Cmd+Shift+P → \"Tasks: Run Task\" → \"${I_KEY} Claude: Login\"${NC}"
    echo -e "        ${DIM}Or in terminal:${NC} ${GREEN}claude login${NC}"
    echo ""
    echo -e "    ${YELLOW}4.${NC}  Start Claude!"
    echo -e "        ${DIM}Wait for Claude Code extension to install, then use it normally.${NC}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Available VS Code Tasks:${NC}"
    echo ""
    echo -e "    ${I_BRAIN}  ${WHITE}Claude: Skip Permissions${NC}      ${DIM}— Interactive mode${NC}"
    echo -e "    ${I_LINK}  ${WHITE}Claude: Resume Last Chat${NC}      ${DIM}— Continue previous chat${NC}"
    echo -e "    ${I_ZAP}  ${WHITE}Claude: One-Shot Task${NC}         ${DIM}— Custom prompt input${NC}"
    echo -e "    ${I_SHIELD}  ${WHITE}Claude: Safe Mode (no rm)${NC}    ${DIM}— Block file deletion${NC}"
    echo -e "    ${I_LOCK}  ${WHITE}Firewall: Re-initialize${NC}      ${DIM}— Re-apply firewall${NC}"
    echo -e "    ${I_KEY}  ${WHITE}Claude: Login${NC}                 ${DIM}— First-time auth${NC}"
    echo ""
    divider
    echo ""
    echo -e "  ${YELLOW}${I_WARN}  ${BOLD}Claude Code Extension:${NC}"
    echo -e "    ${DIM}If the extension is disabled inside the container, install it manually:${NC}"
    echo -e "    ${WHITE}Cmd+Shift+X${NC} ${DIM}→${NC} ${WHITE}Search \"Claude Code\"${NC} ${DIM}→${NC} ${WHITE}Install in Dev Container${NC}"
    echo -e "    ${DIM}This only needs to be done once — it persists across rebuilds.${NC}"
    echo ""
    divider
    echo ""
    echo -e "  ${BOLD}${WHITE}Or use Terminal mode instead:${NC}"
    echo ""
    echo -e "    ${DIM}# Interactive${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} ${target_path}"
    echo ""
    echo -e "    ${DIM}# One-shot task${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} ${target_path} -p \"your task here\""
    echo ""
    echo -e "    ${DIM}# Resume previous conversation${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} ${target_path} --continue"
    echo ""
    echo -e "    ${DIM}# Shell mode (manual Claude start)${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} ${target_path} --shell"
    echo ""
    echo -e "    ${DIM}# Safe mode (block rm commands)${NC}"
    echo -e "    ${GREEN}\$${NC} ${CMD_PREFIX} ${target_path} --disallowedTools \"Bash(rm:*)\""
    echo ""
    divider
    echo ""
}

# ── Progress line helper ─────────────────────────────────────
show_progress_line() {
    local label="$1"
    local status="$2"

    case "$status" in
        running) echo -e "  ${CYAN}▸${NC}  ${label} ${DIM}...${NC}" ;;
        done)    echo -e "  ${GREEN}●${NC}  ${label}" ;;
        skip)    echo -e "  ${YELLOW}○${NC}  ${label}" ;;
        fail)    echo -e "  ${RED}✖${NC}  ${label}" ;;
    esac
}

# ── Update ────────────────────────────────────────────────────
update_sandbox() {
    show_banner
    step "Checking for updates..."
    echo ""

    # Fetch latest version from npm registry
    local latest
    latest=$(curl -sf --max-time 10 "https://registry.npmjs.org/cc-sandboxer/latest" 2>/dev/null \
        | grep -o '"version":"[^"]*"' | head -1 | grep -o '[0-9][0-9.]*') || true

    if [[ -z "$latest" ]]; then
        err "Could not fetch latest version from npm registry"
        exit 1
    fi

    echo -e "    ${DIM}Current:${NC} ${WHITE}v${SCRIPT_VERSION}${NC}"
    echo -e "    ${DIM}Latest:${NC}  ${WHITE}v${latest}${NC}"
    echo ""

    # Check if already up to date
    if [[ "$latest" == "$SCRIPT_VERSION" ]]; then
        success "Already up to date! ${I_CHECK}"
        echo ""
        exit 0
    fi

    # Detect install method and update accordingly
    if [[ "${SCRIPT_DIR}" == *"/_npx/"* ]] || [[ "${SCRIPT_DIR}" == *"/.npm/_npx"* ]]; then
        # npx always fetches latest — clear cache so next run gets new version
        echo -e "  ${I_PACKAGE}  ${BOLD}Install method:${NC} npx"
        echo ""
        step "Clearing npx cache..."
        npx --yes clear-npx-cache 2>/dev/null || npm cache clean --force 2>/dev/null || true
        echo ""
        success "Cache cleared! Next ${GREEN}npx cc-sandboxer${NC} will use ${GREEN}v${latest}${NC} ${I_CHECK}"

    elif [[ "${SCRIPT_DIR}" == *"/node_modules/.bin"* ]] || command -v cc-sandboxer &>/dev/null; then
        # Global npm install
        echo -e "  ${I_PACKAGE}  ${BOLD}Install method:${NC} npm global"
        echo ""
        step "Updating via npm..."
        echo ""
        npm update -g cc-sandboxer
        echo ""
        local new_ver
        new_ver=$(grep -o '"version": *"[^"]*"' "$(npm root -g)/cc-sandboxer/package.json" 2>/dev/null | head -1 | grep -o '[0-9][0-9.]*' || echo "unknown")
        success "Updated to v${new_ver} ${I_CHECK}"

    else
        # Git clone
        echo -e "  ${I_PACKAGE}  ${BOLD}Install method:${NC} git clone"
        echo ""
        step "Updating via git pull..."
        echo ""
        (cd "$SCRIPT_DIR" && git pull)
        echo ""
        local new_ver
        new_ver=$(grep -o '"version": *"[^"]*"' "${SCRIPT_DIR}/package.json" 2>/dev/null | head -1 | grep -o '[0-9][0-9.]*' || echo "unknown")
        success "Updated to v${new_ver} ${I_CHECK}"
    fi

    # Rebuild Docker image with new version
    echo ""
    divider
    echo ""
    step "Rebuilding Docker image with latest version..."
    echo ""
    FORCE_REBUILD=true
    build_image
    echo ""
    success "Update complete! ${I_SPARKLE}"
    echo ""
}

# ── Uninstall ─────────────────────────────────────────────────
uninstall_sandbox() {
    show_banner
    step "Uninstalling cc-sandboxer..."
    echo ""

    # Stop and remove running container
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
        docker rm -f "$CONTAINER_NAME" &>/dev/null || true
        show_progress_line "Removed container ${CONTAINER_NAME}" "done"
    else
        show_progress_line "No running container found" "skip"
    fi

    # Remove Docker image
    if docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null 2>&1; then
        docker rmi "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null || true
        show_progress_line "Removed image ${IMAGE_NAME}:${IMAGE_TAG}" "done"
    else
        show_progress_line "No image found" "skip"
    fi

    # Remove Docker volumes
    local volumes=("claude-config" "claude-npm" "claude-history" "claude-code-config" "claude-code-npm" "claude-code-history")
    for vol in "${volumes[@]}"; do
        if docker volume inspect "$vol" &>/dev/null 2>&1; then
            docker volume rm "$vol" &>/dev/null || true
            show_progress_line "Removed volume ${vol}" "done"
        fi
    done

    # Remove cached temp files
    if [[ -d "${HOME}/.cache/cc-sandboxer" ]]; then
        rm -rf "${HOME}/.cache/cc-sandboxer"
        show_progress_line "Removed cache ${HOME}/.cache/cc-sandboxer" "done"
    fi

    # Remove global npm package
    if command -v npm &>/dev/null && npm list -g cc-sandboxer &>/dev/null 2>&1; then
        npm uninstall -g cc-sandboxer &>/dev/null || true
        show_progress_line "Removed global npm package cc-sandboxer" "done"
    else
        show_progress_line "No global npm package found" "skip"
    fi

    echo ""
    divider
    echo ""
    success "Uninstall complete ${I_CHECK}"
    echo ""
}

# ══════════════════════════════════════════════════════════════
# 🐳 CLI Mode — Docker direct
# ══════════════════════════════════════════════════════════════

# ── Parse args ───────────────────────────────────────────────
PROJECT_PATH=""
CLAUDE_ARGS=()
FORCE_REBUILD=false
SHELL_ONLY=false
NO_FIREWALL=false
INIT_MODE=false
EXTRA_DOMAINS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --init)
            INIT_MODE=true; shift ;;
        --rebuild)
            FORCE_REBUILD=true; shift ;;
        --shell)
            SHELL_ONLY=true; shift ;;
        --no-firewall)
            NO_FIREWALL=true; shift ;;
        --allow-domain)
            if [[ -z "${2:-}" || "$2" == --* ]]; then
                err "--allow-domain requires a domain argument"
                exit 1
            fi
            # Validate domain format (alphanumeric, dots, hyphens, wildcards)
            if [[ ! "$2" =~ ^[a-zA-Z0-9.*-]+$ ]]; then
                err "Invalid domain format: $2"
                exit 1
            fi
            EXTRA_DOMAINS+=("$2"); shift 2 ;;
        --continue|-c)
            CLAUDE_ARGS+=("--continue"); shift ;;
        -p)
            CLAUDE_ARGS+=("-p" "$2"); shift 2 ;;
        --disallowedTools)
            CLAUDE_ARGS+=("--disallowedTools" "$2"); shift 2 ;;
        --update)
            update_sandbox; exit 0 ;;
        --uninstall)
            uninstall_sandbox; exit 0 ;;
        --version|-v)
            echo "cc-sandboxer v${SCRIPT_VERSION}"; exit 0 ;;
        --help|-h)
            show_help; exit 0 ;;
        -*)
            CLAUDE_ARGS+=("$1"); shift ;;
        *)
            if [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$1"
            else
                CLAUDE_ARGS+=("$1")
            fi
            shift ;;
    esac
done

# Default project path
if [[ -z "$PROJECT_PATH" ]]; then
    PROJECT_PATH="$(pwd)"
fi
# Create directory if it doesn't exist (useful for --init with new projects)
if [[ ! -d "$PROJECT_PATH" ]]; then
    if [[ "$INIT_MODE" == "true" ]]; then
        mkdir -p "$PROJECT_PATH"
    else
        err "Project path not found: ${PROJECT_PATH:-<empty>}"
        echo ""
        echo -e "    ${BOLD}${WHITE}Usage:${NC}"
        echo -e "    ${GREEN}${CMD_PREFIX}${NC} ${DIM}[project_path]${NC}"
        echo -e "    ${GREEN}${CMD_PREFIX} --init${NC} ${DIM}~/projects/my-app${NC}"
        echo ""
        exit 1
    fi
fi
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# ── Handle --init mode ──────────────────────────────────────
if [[ "$INIT_MODE" == "true" ]]; then
    init_vscode_project "$PROJECT_PATH"
    exit 0
fi

# ── Detect container runtime ─────────────────────────────────
detect_runtime() {
    step "Detecting container runtime..."

    if ! command -v docker &>/dev/null; then
        err "Docker not found!"
        echo ""
        echo -e "    ${BOLD}Install one of these:${NC}"
        echo -e "    ${I_DOCKER}  Docker Desktop  ${DIM}→${NC}  ${UNDERLINE}https://docker.com/products/docker-desktop${NC}"
        echo -e "    ${I_ROCKET}  OrbStack (Mac)  ${DIM}→${NC}  ${UNDERLINE}https://orbstack.dev${NC}"
        echo ""
        exit 1
    fi

    # Check if Docker daemon is actually running
    if ! docker info &>/dev/null; then
        err "Docker daemon is not running!"
        echo ""
        echo -e "    ${BOLD}Start your container runtime:${NC}"
        echo -e "    ${I_DOCKER}  Docker Desktop  ${DIM}→${NC}  Open the Docker Desktop app"
        echo -e "    ${I_ROCKET}  OrbStack        ${DIM}→${NC}  Open the OrbStack app"
        echo -e "    ${I_DOCKER}  Colima           ${DIM}→${NC}  Run ${GREEN}colima start${NC}"
        echo ""
        exit 1
    fi

    RUNTIME="docker"
    local docker_info
    docker_info=$(docker info 2>/dev/null || true)

    # Check context name first (most reliable), then fall back to docker info
    local docker_context
    docker_context=$(docker context show 2>/dev/null || echo "")

    if [[ "$docker_context" == "orbstack" ]]; then
        RUNTIME_LABEL="OrbStack"
        RUNTIME_ICON="${I_ROCKET}"
    elif [[ "$docker_context" == "colima"* ]]; then
        RUNTIME_LABEL="Colima"
        RUNTIME_ICON="🦙"
    elif [[ "$docker_context" == "desktop-linux" ]] || echo "$docker_info" | grep -qi "docker desktop"; then
        RUNTIME_LABEL="Docker Desktop"
        RUNTIME_ICON="${I_DOCKER}"
    else
        RUNTIME_LABEL="Docker Engine"
        RUNTIME_ICON="${I_DOCKER}"
    fi

    log "Found ${BOLD}${RUNTIME_LABEL}${NC} ${RUNTIME_ICON}"
}

# ── Build image ──────────────────────────────────────────────
build_image() {
    if [[ "$FORCE_REBUILD" == "true" ]] || ! docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null; then
        echo ""
        step "Building sandbox image ${I_PACKAGE}"
        echo ""
        echo -e "    ${DIM}Image:${NC}    ${WHITE}${IMAGE_NAME}:${IMAGE_TAG}${NC}"
        echo -e "    ${DIM}Timezone:${NC} ${WHITE}${TZ}${NC}"
        echo ""

        echo -e "    ${DIM}${I_CLOCK} Building... (first run takes 2-3 min)${NC}"
        echo ""

        local build_log
        build_log=$(mktemp /tmp/cc-sandboxer-build-XXXXXXXX)

        # Count total steps from Dockerfile (each instruction = 1 step)
        local total_steps
        total_steps=$(grep -cE '^\s*(FROM|RUN|COPY|ADD|ENV|ARG|WORKDIR|USER|ENTRYPOINT|CMD|EXPOSE|VOLUME|LABEL|SHELL)\b' "${SCRIPT_DIR}/docker/Dockerfile")
        local current_step=0
        local bar_width=40

        docker build \
            --build-arg "TZ=$TZ" \
            -t "$IMAGE_NAME:$IMAGE_TAG" \
            "${SCRIPT_DIR}/docker" > "$build_log" 2>&1 &
        local build_pid=$!

        # Prepare-phase: show gradual progress 0% → 10% while waiting for first step
        local prepare_pct=0
        local prepare_max=70
        local prepare_tick=0

        # Monitor build progress by watching log for step markers
        while kill -0 "$build_pid" 2>/dev/null; do
            if [[ -f "$build_log" ]]; then
                # Match both legacy "Step N/M" and BuildKit "#N [stage N/M]" formats
                local step_line
                step_line=$(grep -oE '(Step [0-9]+/[0-9]+|#[0-9]+ \[[a-z]+ +[0-9]+/[0-9]+\])' "$build_log" 2>/dev/null | tail -1 || true)
                if [[ -n "$step_line" ]]; then
                    # Extract current/total from either format
                    local nums
                    nums=$(echo "$step_line" | grep -oE '[0-9]+/[0-9]+' | tail -1)
                    current_step=${nums%/*}
                    total_steps=${nums#*/}
                fi

                if [[ "$current_step" -eq 0 ]]; then
                    # Gradually increase from 0% to prepare_max% during prepare phase
                    prepare_tick=$(( prepare_tick + 1 ))
                    # Increase every ~3 ticks (0.9s) up to prepare_max
                    if [[ $(( prepare_tick % 3 )) -eq 0 && "$prepare_pct" -lt "$prepare_max" ]]; then
                        prepare_pct=$(( prepare_pct + 1 ))
                    fi
                    local filled=$(( prepare_pct * bar_width / 100 ))
                    local empty=$(( bar_width - filled ))
                    local bar="${CYAN}$(printf '%*s' "$filled" '' | tr ' ' '▓')${GRAY}$(printf '%*s' "$empty" '' | tr ' ' '░')${NC}"
                    printf "\r    ${bar} ${BOLD}${CYAN}%3d%%${NC} ${DIM}Preparing...${NC}  " "$prepare_pct"
                elif [[ "$total_steps" -gt 0 ]]; then
                    # Map real progress (step/total) into remaining 10%-100% range
                    local real_pct=$(( current_step * 100 / total_steps ))
                    local pct=$(( prepare_max + real_pct * (100 - prepare_max) / 100 ))
                    local filled=$(( pct * bar_width / 100 ))
                    local empty=$(( bar_width - filled ))
                    # Gradient color: cyan → green → yellow as progress increases
                    local bar_color
                    if [[ "$pct" -lt 33 ]]; then
                        bar_color="${CYAN}"
                    elif [[ "$pct" -lt 66 ]]; then
                        bar_color="${GREEN}"
                    else
                        bar_color="${YELLOW}"
                    fi
                    local bar="${bar_color}$(printf '%*s' "$filled" '' | tr ' ' '▓')${GRAY}$(printf '%*s' "$empty" '' | tr ' ' '░')${NC}"
                    printf "\r    ${bar} ${BOLD}${bar_color}%3d%%${NC} ${DIM}(%d/%d)${NC} " "$pct" "$current_step" "$total_steps"
                fi
            fi
            sleep 0.3
        done

        # Final status
        wait "$build_pid"
        local build_exit=$?

        if [[ "$build_exit" -eq 0 ]]; then
            printf "\r    ${GREEN}$(printf '%*s' "$bar_width" '' | tr ' ' '▓')${NC} ${BOLD}${GREEN}100%%${NC} ${DIM}(%d/%d)${NC} \n" "$total_steps" "$total_steps"
            echo ""
            log "Image built successfully ${I_SPARKLE}"
            rm -f "$build_log"
        else
            echo ""
            err "Image build failed!"
            echo ""
            echo -e "    ${BOLD}${WHITE}Last 20 lines of build output:${NC}"
            echo ""
            tail -20 "$build_log" | while IFS= read -r line; do
                echo -e "    ${DIM}${line}${NC}"
            done
            echo ""
            echo -e "    ${DIM}Full build log:${NC} ${WHITE}${build_log}${NC}"
            echo ""
            echo -e "    ${BOLD}${WHITE}Common fixes:${NC}"
            echo -e "    ${YELLOW}•${NC}  Network issue     ${DIM}→${NC}  Check internet connection"
            echo -e "    ${YELLOW}•${NC}  Disk full          ${DIM}→${NC}  Run ${GREEN}docker system prune${NC}"
            echo -e "    ${YELLOW}•${NC}  Cached layers      ${DIM}→${NC}  Run ${GREEN}$0 --rebuild${NC}"
            echo ""
            exit 1
        fi

    else
        log "Image ${BOLD}${IMAGE_NAME}:${IMAGE_TAG}${NC} ready ${DIM}(use --rebuild to force)${NC}"
    fi
}

# ── Generate firewall script to temp file ─────────────────────
# Writes firewall script to a temp file to avoid shell injection
# when embedding in docker run -c commands
gen_firewall_file() {
    local fw_file="$1"
    # Copy the canonical firewall script and inject extra domains
    cp "${SCRIPT_DIR}/docker/init-firewall.sh" "$fw_file"

    # Inject extra domains into the ALLOWED_DOMAINS array
    if [[ ${#EXTRA_DOMAINS[@]} -gt 0 ]]; then
        local extra_lines=""
        for d in "${EXTRA_DOMAINS[@]}"; do
            [[ -n "$d" ]] && extra_lines+="    \"$d\"\n"
        done
        if [[ -n "$extra_lines" ]]; then
            # Insert extra domains before the closing paren of ALLOWED_DOMAINS
            local tmp_fw="${fw_file}.tmp"
            awk -v extra="$extra_lines" '/^)$/ && !done { printf "%s", extra; done=1 } { print }' "$fw_file" > "$tmp_fw"
            mv "$tmp_fw" "$fw_file"
        fi
    fi

    chmod +x "$fw_file"
}

# ── Status box ───────────────────────────────────────────────
show_launch_box() {
    local mode="$1"
    local box_w=55

    # Print a row: icon, label, value, value_color
    # Fixed inner width of 55 chars between │ and │
    box_row() {
        local icon="$1" label="$2" value="$3" vcolor="$4"
        local line
        # Build the visible content: "  X  Label__  Value"
        # icon takes 2 display cols, so we account for that
        line=$(printf "  %s  %-9s  %s" "$icon" "$label" "$value")
        # Calculate visible width (strip ANSI, account for emoji = 2 cols each)
        local visible_len=$(( 2 + 2 + 2 + 9 + 2 + ${#value} ))  # emoji=2 display cols
        local pad_len=$(( box_w - visible_len ))
        [[ "$pad_len" -lt 0 ]] && pad_len=0
        printf "  ${BOLD}${CYAN}│${NC}  %s  ${DIM}%-9s${NC}  ${vcolor}%s${NC}%*s${BOLD}${CYAN}│${NC}\n" \
            "$icon" "$label" "$value" "$pad_len" ""
    }

    echo ""
    echo -e "  ${BOLD}${CYAN}┌───────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${BOLD}${CYAN}│${NC}  ${I_BRAIN}  ${BOLD}${WHITE}Claude Code Sandbox${NC}                              ${BOLD}${CYAN}│${NC}"
    echo -e "  ${BOLD}${CYAN}├───────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${BOLD}${CYAN}│${NC}                                                       ${BOLD}${CYAN}│${NC}"

    box_row "$I_FOLDER"  "Project :" "$PROJECT_NAME"  "${WHITE}"
    box_row "$RUNTIME_ICON" "Runtime :" "$RUNTIME_LABEL" "${WHITE}"
    box_row "$I_ZAP"     "Mode    :" "$mode"           "${WHITE}"

    if [[ "$NO_FIREWALL" == "true" ]]; then
        box_row "$I_GLOBE" "Firewall:" "Disabled" "${YELLOW}"
    else
        box_row "$I_LOCK"  "Firewall:" "Active"   "${GREEN}"
    fi

    echo -e "  ${BOLD}${CYAN}│${NC}                                                       ${BOLD}${CYAN}│${NC}"
    echo -e "  ${BOLD}${CYAN}└───────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ── Run container ────────────────────────────────────────────
run_container() {
    step "Launching container ${I_ROCKET}"

    # Cleanup existing
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker rm -f "$CONTAINER_NAME" &>/dev/null || true
    fi

    local RUN_ARGS=(
        --rm -it
        --name "$CONTAINER_NAME"
        --cap-add=NET_ADMIN
        -v "$PROJECT_PATH:/workspace:cached"
        -v "${HOME}/.claude:/home/node/.claude:cached"
        -v "claude-npm:/usr/local/share/npm-global"
        -v "claude-history:/commandhistory"
        -e "CLAUDE_CONFIG_DIR=/home/node/.claude"
        -e "TZ=$TZ"
    )

    # Mount .gitconfig if exists
    if [[ -f "${HOME}/.gitconfig" ]]; then
        RUN_ARGS+=(-v "${HOME}/.gitconfig:/home/node/.gitconfig:ro")
    fi

    # Generate firewall script as temp file and mount into container
    local FW_SETUP="true"
    if [[ "$NO_FIREWALL" == "false" ]]; then
        local fw_tmp
        # Colima only shares $HOME into its VM — /tmp and $TMPDIR (/var/folders)
        # are not accessible, causing Docker to mount them as empty directories.
        # Place temp file under $HOME to ensure visibility across all runtimes.
        local tmp_base="${HOME}/.cache/cc-sandboxer"
        mkdir -p "$tmp_base"
        fw_tmp=$(mktemp "${tmp_base}/fw-XXXXXXXX")
        gen_firewall_file "$fw_tmp"
        RUN_ARGS+=(-v "$fw_tmp:/opt/init-firewall.sh:ro")
        FW_SETUP="sudo bash /opt/init-firewall.sh"
    fi

    # Build claude command as an array to avoid injection
    local CLAUDE_CMD="claude --dangerously-skip-permissions"
    if [[ ${#CLAUDE_ARGS[@]} -gt 0 ]]; then
        # Quote each arg individually for safe embedding
        for arg in "${CLAUDE_ARGS[@]}"; do
            CLAUDE_CMD+=" $(printf '%q' "$arg")"
        done
    fi

    if [[ "$SHELL_ONLY" == "true" ]]; then
        show_launch_box "Shell Only"

        docker run "${RUN_ARGS[@]}" "$IMAGE_NAME:$IMAGE_TAG" -c "
            ${FW_SETUP} 2>/tmp/fw-err.log || { echo -e '\033[1;33m⚠ Firewall failed to initialize.\033[0m Ensure container has --cap-add=NET_ADMIN.'; cat /tmp/fw-err.log; echo ''; }
            echo ''
            echo 'Shell ready! Start Claude manually:'
            echo ''
            echo '   claude --dangerously-skip-permissions'
            echo '   claude --dangerously-skip-permissions -p \"your task\"'
            echo '   claude --dangerously-skip-permissions --continue'
            echo ''
            exec zsh -l
        "
    else
        show_launch_box "Skip Permissions"

        echo -e "    ${DIM}${I_ZAP} ${CLAUDE_CMD}${NC}"
        echo ""
        divider
        echo ""

        docker run "${RUN_ARGS[@]}" "$IMAGE_NAME:$IMAGE_TAG" -c "
            ${FW_SETUP} 2>/tmp/fw-err.log || { echo -e '\033[1;33m⚠ Firewall failed to initialize.\033[0m Ensure container has --cap-add=NET_ADMIN.'; cat /tmp/fw-err.log; echo ''; }
            ${CLAUDE_CMD}
        "
    fi

    # Cleanup temp firewall file
    [[ -f "${fw_tmp:-}" ]] && rm -f "$fw_tmp"
}

# ══════════════════════════════════════════════════════════════
# 🏁 Main
# ══════════════════════════════════════════════════════════════
main() {
    check_update_background
    show_banner
    detect_runtime

    echo ""
    build_image

    # --rebuild: just build and exit, don't run Claude
    if [[ "$FORCE_REBUILD" == true ]]; then
        echo ""
        success "Rebuild complete ${I_SPARKLE}"
        show_update_notice
        echo ""
        exit 0
    fi

    echo ""
    run_container

    # Post-exit
    echo ""
    divider
    echo ""
    success "Session ended. Your project files are safe ${I_SHIELD}"
    echo ""
    divider
    echo ""
    echo -e "  ${BOLD}${WHITE}Next steps:${NC}"
    echo ""
    echo -e "    ${YELLOW}1.${NC}  Run again (interactive)"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} ${PROJECT_PATH}"
    echo ""
    echo -e "    ${YELLOW}2.${NC}  Resume this conversation"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} ${PROJECT_PATH} --continue"
    echo ""
    echo -e "    ${YELLOW}3.${NC}  One-shot task"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} ${PROJECT_PATH} -p \"your task here\""
    echo ""
    echo -e "    ${YELLOW}4.${NC}  Shell mode (manual Claude start)"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} ${PROJECT_PATH} --shell"
    echo ""
    echo -e "    ${YELLOW}5.${NC}  Safe mode (block rm commands)"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} ${PROJECT_PATH} --disallowedTools \"Bash(rm:*)\""
    echo ""
    echo -e "    ${YELLOW}6.${NC}  Add custom domains to firewall"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} ${PROJECT_PATH} --allow-domain \"api.example.com\""
    echo ""
    echo -e "    ${YELLOW}7.${NC}  Setup VS Code DevContainer"
    echo -e "        ${GREEN}\$${NC} ${CMD_PREFIX} --init ${PROJECT_PATH}"
    echo ""
    show_update_notice
    echo ""
}

main

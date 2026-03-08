# Claude Code Sandbox

**English** | [Tiếng Việt](README.vi.md) | [中文](README.zh.md)

```text
       ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
      ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
      ██║     ██║     ███████║██║   ██║██║  ██║█████╗
      ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝
      ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
       ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
                C O D E   S A N D B O X
```

**Run `claude --dangerously-skip-permissions` safely inside a Docker sandbox.**

One command. Full isolation. Terminal or VS Code.

[![Docker][docker-badge]][docker-url]
[![OrbStack][orbstack-badge]][orbstack-url]
[![VS Code][vscode-badge]][vscode-url]
[![License: MIT][license-badge]][license-url]

[docker-badge]: https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white
[docker-url]: https://www.docker.com/
[orbstack-badge]: https://img.shields.io/badge/OrbStack-Compatible-000000?style=for-the-badge
[orbstack-url]: https://orbstack.dev/
[vscode-badge]: https://img.shields.io/badge/VS_Code-DevContainer-007ACC?style=for-the-badge&logo=visual-studio-code&logoColor=white
[vscode-url]: https://code.visualstudio.com/
[license-badge]: https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge
[license-url]: LICENSE

---

## Quick Start

### Via npx (recommended)

```bash
# Run in current directory
npx cc-sandboxer

# Run with a specific project
npx cc-sandboxer ~/projects/my-app

# One-shot task
npx cc-sandboxer . -p "Fix all lint errors"

# Setup VS Code DevContainer
npx cc-sandboxer --init ~/projects/my-app
```

### Via git clone

```bash
git clone https://github.com/ngocquang/cc-sandbox.git
cd cc-sandbox
chmod +x cc-sandboxer.sh
./cc-sandboxer.sh
```

### VS Code (DevContainer)

```bash
# Setup DevContainer in your project
npx cc-sandboxer --init ~/projects/my-app

# Open in VS Code -> Reopen in Container -> Run tasks
code ~/projects/my-app
```

> First run builds a Docker image (~2-3 min). After that, startup takes seconds.

---

## Why?

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) with `--dangerously-skip-permissions` is incredibly productive — Claude can execute **any** command without prompting. But running it on your bare machine is risky:

|              | Without Sandbox              | With Sandbox                    |
| ------------ | ---------------------------- | ------------------------------- |
| Filesystem   | Full access to your machine  | Only `/workspace`               |
| Network      | Unrestricted internet        | Firewall whitelist only         |
| Outbound TCP | All ports open               | All non-whitelisted TCP blocked |
| Worst case   | `rm -rf /` nukes your system | Container dies, host is fine    |
| Overhead     | None                         | ~3 seconds                      |

---

## Installation

### Option A — npx (no install needed)

```bash
npx cc-sandboxer
```

### Option B — Global install

```bash
npm install -g cc-sandboxer
cc-sandboxer
```

### Option C — Clone the repo

```bash
git clone https://github.com/ngocquang/cc-sandbox.git
cd cc-sandbox
chmod +x cc-sandboxer.sh
./cc-sandboxer.sh
```

### Shell Alias (optional)

Add to your `~/.zshrc` or `~/.bashrc` for quick access:

```bash
alias cc="npx cc-sandboxer"
```

Then reload your shell:

```bash
source ~/.zshrc
```

Now you can use:

```bash
cc                          # current directory
cc ~/projects/my-app        # specific project
cc . -p "Fix all lint errors"
cc . --continue
```

### Prerequisites

You need **one** of these container runtimes:

> **Note:** Supports **macOS** and **Linux** only. Windows is not supported.

| Runtime        | Platform      | Install                                                       |
| -------------- | ------------- | ------------------------------------------------------------- |
| Docker Desktop | macOS / Linux | [docker.com](https://www.docker.com/products/docker-desktop/) |
| OrbStack       | macOS         | [orbstack.dev](https://orbstack.dev/)                         |
| Colima         | macOS / Linux | [github](https://github.com/abiosoft/colima)                  |
| Docker Engine  | Linux         | [docs.docker.com](https://docs.docker.com/engine/install/)    |

For VS Code mode, also install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

---

## Terminal Mode

### Interactive (recommended)

```bash
cc-sandboxer                     # current directory
cc-sandboxer ~/projects/my-app   # specific project
```

### One-shot tasks

```bash
cc-sandboxer . -p "Refactor the auth module and write tests"
cc-sandboxer . -p "Fix all ESLint errors and add missing types"
cc-sandboxer . -p "Read SPEC.md -> write failing tests -> implement -> iterate"
```

### Resume previous conversation

```bash
cc-sandboxer . --continue
```

### Block dangerous commands

```bash
cc-sandboxer . --disallowedTools "Bash(rm:*)"
```

### Shell mode

```bash
cc-sandboxer --shell
# Then run manually inside:
#   claude --dangerously-skip-permissions
```

> All commands work with `npx cc-sandboxer`, `cc-sandboxer` (global install), or `./cc-sandboxer.sh` (cloned repo).

---

## VS Code Mode

The `--init` flag sets up a full DevContainer environment in your project — no manual config needed.

### Setup

```bash
./cc-sandboxer.sh --init ~/projects/my-app
```

This creates:

```text
your-project/
├── devcontainer/
│   ├── Dockerfile             # Sandbox image with all tools
│   ├── devcontainer.json      # VS Code container config
│   └── init-firewall.sh       # Network security rules
└── .vscode/
    └── tasks.json             # Pre-configured Claude tasks
```

### Recommended: Install Claude Code Extension

For the best experience in DevContainer, install the [Claude Code extension](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) in VS Code **before** opening the container. The DevContainer is pre-configured to auto-install it inside the container, but having it on the host ensures seamless setup.

> **Tip:** The extension provides a native VS Code GUI for Claude Code — chat panel, inline suggestions, and task management — all within the sandbox.

### Open in VS Code

```text
1.  code ~/projects/my-app
2.  Cmd+Shift+P -> "Dev Containers: Reopen in Container"
3.  Wait for build (first time only)
4.  The Claude Code extension auto-installs inside the container.
5.  Done! You're inside the sandbox.
```

### VS Code Tasks

Once inside the container, use `Cmd+Shift+P` -> `Tasks: Run Task`:

| Task                      | Description                        |
| ------------------------- | ---------------------------------- |
| Claude: Skip Permissions  | Interactive mode                   |
| Claude: Resume Last Chat  | Continue previous conversation     |
| Claude: One-Shot Task     | Prompts you for a task description |
| Claude: Safe Mode (no rm) | Skip permissions but block `rm`    |
| Firewall: Re-initialize   | Re-apply network rules             |
| Claude: Login             | First-time authentication          |

### First-time Authentication

```bash
# Run the login task, or in terminal:
claude login
```

The auth token is persisted in a Docker volume — you only need to do this once.

---

## Security

### Network Firewall

The container runs an `iptables` firewall with **default-deny for all outbound TCP**. Only whitelisted domains are allowed:

| Service        | Domains                                                            |
| -------------- | ------------------------------------------------------------------ |
| Claude API     | `api.anthropic.com`, `auth.anthropic.com`, `statsig.anthropic.com`, `sentry.io`, `anthropic.gallerycdn.azure.cn` |
| Claude Code    | `storage.googleapis.com`                                           |
| npm            | `registry.npmjs.org`, `registry.yarnpkg.com`                       |
| GitHub         | `github.com`, `api.github.com`, `*.githubusercontent.com`          |
| PyPI           | `pypi.org`, `files.pythonhosted.org`                               |
| Microsoft      | `microsoft.com`                                                    |
| VS Code        | `marketplace.visualstudio.com`, `open-vsx.org`, `*.vo.msecnd.net`, `gallerycdn.vsassets.io`, `vscode.download.prss.microsoft.com`, `default.exp-tas.com` |

**Everything else is blocked.** Claude can't exfiltrate code or download from untrusted sources.

Key security features:

- **All outbound TCP blocked** by default (not just ports 80/443)
- **DNS tunneling mitigated** — DNS queries restricted to local resolvers only
- **Input validation** — domain names validated before adding to whitelist
- **No seccomp=unconfined** — only `NET_ADMIN` capability granted for iptables

#### Add custom domains

```bash
# CLI mode
./cc-sandboxer.sh --allow-domain "api.example.com" --allow-domain "docker.io"

# DevContainer mode — edit devcontainer/init-firewall.sh
# Or set the env var in devcontainer.json:
#   "containerEnv": { "EXTRA_ALLOWED_DOMAINS": "api.example.com,docker.io" }
```

### Filesystem Isolation

| What            | Access                    |
| --------------- | ------------------------- |
| Your project    | Mounted at `/workspace`   |
| Host filesystem | Isolated                  |
| `.gitconfig`    | Read-only                 |
| Auth tokens     | Docker volume (persisted) |

---

## Configuration

### Environment Variables

| Variable                | Default            | Description                                         |
| ----------------------- | ------------------ | --------------------------------------------------- |
| `TZ`                    | `Asia/Ho_Chi_Minh` | Container timezone                                  |
| `EXTRA_ALLOWED_DOMAINS` | _(empty)_          | Comma-separated domains for firewall (DevContainer) |

```bash
TZ=America/New_York ./cc-sandboxer.sh
```

### Customize DevContainer

After running `--init`, you can edit any file in `devcontainer/`:

**Add tools** — edit `devcontainer/Dockerfile`:

```dockerfile
# Add Python ML tools
RUN pip3 install --break-system-packages numpy pandas

# Add Go
RUN curl -OL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
```

**Add VS Code extensions** — edit `devcontainer/devcontainer.json`:

```jsonc
"customizations": {
    "vscode": {
        "extensions": [
            "anthropic.claude-code",
            "dbaeumer.vscode-eslint",
            "esbenp.prettier-vscode"
        ]
    }
}
```

Then rebuild: `Cmd+Shift+P` -> `Dev Containers: Rebuild Container`

---

## What's in the Box?

| Category     | Tools                           |
| ------------ | ------------------------------- |
| **Runtime**  | Node.js 20, Python 3, npm, pip  |
| **Editor**   | nano, vim                       |
| **Search**   | ripgrep (`rg`), fd-find         |
| **VCS**      | git, gh (GitHub CLI), git-delta |
| **Shell**    | zsh, Oh My Zsh, fzf             |
| **Network**  | curl, wget, jq                  |
| **Security** | iptables, ipset, dnsutils       |

---

## All CLI Options

```text
Usage: cc-sandboxer [project_path] [options]

Arguments:
  project_path              Path to project (default: current directory)

Setup:
  --init                    Setup devcontainer + VS Code tasks in project
  --rebuild                 Force rebuild Docker image
  --version, -v             Show version
  --help, -h                Show help

Runtime:
  --shell                   Open shell without starting Claude
  --no-firewall             Skip network firewall
  --allow-domain NAME       Whitelist extra domain (repeatable)
  --continue, -c            Resume previous conversation
  -p "prompt"               One-shot task mode
  --disallowedTools TOOLS   Block specific Claude tools
```

---

## Cleanup

```bash
# Remove persisted data
docker volume rm claude-config claude-npm claude-history

# Remove image
docker rmi cc-sandboxer:latest

# Remove DevContainer volumes
docker volume rm claude-code-config claude-code-npm claude-code-history
```

---

## Troubleshooting

### "Firewall skipped"

The container needs `NET_ADMIN` capability.
In CLI mode, this is set automatically.
In DevContainer mode, check that `devcontainer.json` has:

```json
"runArgs": ["--cap-add=NET_ADMIN"]
```

### Claude not authenticated

```bash
# CLI mode
./cc-sandboxer.sh --shell
claude login

# VS Code mode
# Cmd+Shift+P -> Tasks: Run Task -> Claude: Login
```

### First build is slow

First build downloads Node.js, system packages, and Claude Code (~2-3 min).
Subsequent runs use the cached image.
Force rebuild to update Claude Code:

```bash
./cc-sandboxer.sh --rebuild
# or in VS Code:
# Cmd+Shift+P -> Dev Containers: Rebuild Container
```

### Need a blocked domain

```bash
# CLI
./cc-sandboxer.sh --allow-domain "your-domain.com"

# DevContainer
# add to init-firewall.sh ALLOWED_DOMAINS array
# or set env:
# EXTRA_ALLOWED_DOMAINS="domain1.com,domain2.com"
```

### Claude Code extension not working in container

If you see: _"This extension is disabled in this workspace because it is defined to run in the Remote Extension Host"_

**Fix (one-time):**

1. Open the **Extensions** sidebar (`Cmd+Shift+X`)
2. Search for **"Claude Code"**
3. Click **"Install in Dev Container"**
4. The extension is now persisted in a Docker volume — it survives container rebuilds

> **Why?** The Claude Code extension requires installation inside the container's Remote Extension Host. The DevContainer config attempts auto-install, but some VS Code setups require a one-time manual install. After that, the volume mount keeps it available permanently.

---

## Testing

Unit tests use [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

### Install & Run

```bash
# Install bats (macOS)
brew install bats-core

# Run all tests
bats tests/

# Run specific test file
bats tests/cc-sandbox.bats
bats tests/init-firewall.bats
```

### Coverage

| Area | Tests | What's covered |
| --- | --- | --- |
| CLI flags | 5 | `--version`, `-v`, `--help`, `-h`, all documented options |
| Domain validation | 5 | Missing arg, flag collision, special chars, spaces, slashes |
| `--init` mode | 10 | File creation, no-overwrite, content validation, source parity |
| Firewall generation | 7 | Default/extra domains, iptables rules, DNS tunneling, SSH, syntax |
| Firewall script | 19 | Syntax, domains, security rules, ipset ordering, regex validation |
| Display | 3 | Banner, version string, ASCII art |
| **Total** | **49** | |

---

## Contributing

PRs welcome! Some ideas:

- [ ] Add Cursor IDE support
- [ ] Add Windsurf support
- [ ] Per-project firewall configs

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

**Built for developers who like their `rm -rf` contained.**

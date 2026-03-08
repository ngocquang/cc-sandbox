# Claude Code Sandbox

[English](README.md) | [Tiếng Việt](README.vi.md) | **中文**

```text
       ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
      ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
      ██║     ██║     ███████║██║   ██║██║  ██║█████╗
      ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝
      ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
       ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
                C O D E   S A N D B O X
```

**在 Docker 沙箱中安全运行 `claude --dangerously-skip-permissions`。**

一条命令。完全隔离。支持终端或 VS Code。

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

## 快速开始

### 通过 npx（推荐）

```bash
# 在当前目录运行
npx cc-sandboxer

# 指定项目运行
npx cc-sandboxer ~/projects/my-app

# 一次性任务
npx cc-sandboxer . -p "修复所有 lint 错误"

# 设置 VS Code DevContainer
npx cc-sandboxer --init ~/projects/my-app
```

### 通过 git clone

```bash
git clone https://github.com/ngocquang/cc-sandbox.git
cd cc-sandbox
chmod +x cc-sandboxer.sh
./cc-sandboxer.sh
```

### VS Code（DevContainer）

```bash
# 在项目中设置 DevContainer
npx cc-sandboxer --init ~/projects/my-app

# 在 VS Code 中打开 -> 在容器中重新打开 -> 运行任务
code ~/projects/my-app
```

> 首次运行需要构建 Docker 镜像（约2-3分钟）。之后启动只需几秒。

---

## 为什么需要沙箱？

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) 配合 `--dangerously-skip-permissions` 非常高效 — Claude 可以**无需确认**执行任何命令。但在裸机上运行风险很大：

|              | 无沙箱                      | 有沙箱                          |
| ------------ | --------------------------- | ------------------------------- |
| 文件系统      | 完全访问你的机器              | 仅限 `/workspace`               |
| 网络          | 不受限的互联网                | 仅白名单域名                    |
| 出站 TCP      | 所有端口开放                  | 非白名单 TCP 全部阻止            |
| 最坏情况      | `rm -rf /` 摧毁你的系统       | 容器崩溃，主机无影响             |
| 额外开销      | 无                           | 约3秒                           |

---

## 安装

### 方式 A — npx（无需安装）

```bash
npx cc-sandboxer
```

### 方式 B — 全局安装

```bash
npm install -g cc-sandboxer
cc-sandboxer
```

### 方式 C — 克隆仓库

```bash
git clone https://github.com/ngocquang/cc-sandbox.git
cd cc-sandbox
chmod +x cc-sandboxer.sh
./cc-sandboxer.sh
```

### Shell 别名（可选）

添加到 `~/.zshrc` 或 `~/.bashrc` 以便快速访问：

```bash
alias cc="npx cc-sandboxer"
```

然后重新加载 shell：

```bash
source ~/.zshrc
```

现在你可以使用：

```bash
cc                          # 当前目录
cc ~/projects/my-app        # 指定项目
cc . -p "修复所有 lint 错误"
cc . --continue
```

### 前置要求

你需要以下容器运行时**之一**：

> **注意：** 仅支持 **macOS** 和 **Linux**。不支持 Windows。

| 运行时          | 平台           | 安装                                                          |
| --------------- | -------------- | ------------------------------------------------------------- |
| Docker Desktop  | macOS / Linux  | [docker.com](https://www.docker.com/products/docker-desktop/) |
| OrbStack        | macOS          | [orbstack.dev](https://orbstack.dev/)                         |
| Colima          | macOS / Linux  | [github](https://github.com/abiosoft/colima)                  |
| Docker Engine   | Linux          | [docs.docker.com](https://docs.docker.com/engine/install/)    |

VS Code 模式还需安装 [Dev Containers 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)。

---

## 终端模式

### 交互式（推荐）

```bash
cc-sandboxer                     # 当前目录
cc-sandboxer ~/projects/my-app   # 指定项目
```

### 一次性任务

```bash
cc-sandboxer . -p "重构 auth 模块并编写测试"
cc-sandboxer . -p "修复所有 ESLint 错误并补充缺失的类型"
cc-sandboxer . -p "读取 SPEC.md -> 编写失败测试 -> 实现 -> 迭代"
```

### 继续上次对话

```bash
cc-sandboxer . --continue
```

### 阻止危险命令

```bash
cc-sandboxer . --disallowedTools "Bash(rm:*)"
```

### Shell 模式

```bash
cc-sandboxer --shell
# 然后在里面手动运行：
#   claude --dangerously-skip-permissions
```

> 所有命令均可使用 `npx cc-sandboxer`、`cc-sandboxer`（全局安装）或 `./cc-sandboxer.sh`（克隆仓库）。

---

## VS Code 模式

`--init` 标志在你的项目中设置完整的 DevContainer 环境 — 无需手动配置。

### 设置

```bash
./cc-sandboxer.sh --init ~/projects/my-app
```

这会创建：

```text
your-project/
├── devcontainer/
│   ├── Dockerfile             # 包含所有工具的沙箱镜像
│   ├── devcontainer.json      # VS Code 容器配置
│   └── init-firewall.sh       # 网络安全规则
└── .vscode/
    └── tasks.json             # 预配置的 Claude 任务
```

### 推荐：安装 Claude Code 扩展

为了在 DevContainer 中获得最佳体验，请在打开容器**之前**在 VS Code 中安装 [Claude Code 扩展](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)。DevContainer 已预配置为在容器内自动安装该扩展，但在主机上预先安装可确保无缝设置。

> **提示：** 该扩展提供 Claude Code 的原生 VS Code 界面 — 聊天面板、内联建议和任务管理 — 全部在沙箱内运行。

### 在 VS Code 中打开

```text
1.  code ~/projects/my-app
2.  Cmd+Shift+P -> "Dev Containers: Reopen in Container"
3.  等待构建（仅首次）
4.  Claude Code 扩展在容器内自动安装。
5.  完成！你已经在沙箱内了。
```

### VS Code 任务

进入容器后，使用 `Cmd+Shift+P` -> `Tasks: Run Task`：

| 任务                       | 描述                          |
| ------------------------- | ----------------------------- |
| Claude: Skip Permissions  | 交互模式                       |
| Claude: Resume Last Chat  | 继续上次对话                    |
| Claude: One-Shot Task     | 提示你输入任务描述               |
| Claude: Safe Mode (no rm) | 跳过权限但阻止 `rm`             |
| Firewall: Re-initialize   | 重新应用网络规则                 |
| Claude: Login             | 首次身份验证                    |

### 首次身份验证

```bash
# 运行登录任务，或在终端中：
claude login
```

身份验证令牌保存在 Docker volume 中 — 只需操作一次。

---

## 安全

### 网络防火墙

容器运行 `iptables` 防火墙，**默认阻止所有出站 TCP**。仅允许白名单域名：

| 服务           | 域名                                                               |
| -------------- | ------------------------------------------------------------------ |
| Claude API     | `api.anthropic.com`、`auth.anthropic.com`、`statsig.anthropic.com`、`sentry.io`、`anthropic.gallerycdn.azure.cn` |
| Claude Code    | `storage.googleapis.com`                                           |
| npm            | `registry.npmjs.org`、`registry.yarnpkg.com`                       |
| GitHub         | `github.com`、`api.github.com`、`*.githubusercontent.com`          |
| PyPI           | `pypi.org`、`files.pythonhosted.org`                               |
| Microsoft      | `microsoft.com`                                                    |
| VS Code        | `marketplace.visualstudio.com`、`open-vsx.org`、`*.vo.msecnd.net`、`gallerycdn.vsassets.io` |

**其他一切均被阻止。** Claude 无法泄露代码或从不受信任的来源下载。

主要安全特性：

- **默认阻止所有出站 TCP**（不仅是端口 80/443）
- **缓解 DNS 隧道** — DNS 查询仅限本地解析器
- **输入验证** — 域名在添加到白名单前会被验证
- **不使用 seccomp=unconfined** — 仅授予 `NET_ADMIN` 权限用于 iptables

#### 添加自定义域名

```bash
# CLI 模式
./cc-sandboxer.sh --allow-domain "api.example.com" --allow-domain "docker.io"

# DevContainer 模式 — 编辑 devcontainer/init-firewall.sh
# 或在 devcontainer.json 中设置环境变量：
#   "containerEnv": { "EXTRA_ALLOWED_DOMAINS": "api.example.com,docker.io" }
```

### 文件系统隔离

| 项目            | 访问权限                  |
| --------------- | ------------------------ |
| 你的项目         | 挂载到 `/workspace`      |
| 主机文件系统      | 隔离                     |
| `.gitconfig`    | 只读                     |
| 身份验证令牌      | Docker volume（持久化）   |

---

## 配置

### 环境变量

| 变量                    | 默认值              | 描述                                          |
| ----------------------- | ------------------- | --------------------------------------------- |
| `TZ`                    | `Asia/Ho_Chi_Minh`  | 容器时区                                       |
| `EXTRA_ALLOWED_DOMAINS` | _（空）_             | 逗号分隔的域名，用于防火墙（DevContainer）        |

```bash
TZ=America/New_York ./cc-sandboxer.sh
```

### 自定义 DevContainer

运行 `--init` 后，你可以编辑 `devcontainer/` 中的任何文件：

**添加工具** — 编辑 `devcontainer/Dockerfile`：

```dockerfile
# 添加 Python ML 工具
RUN pip3 install --break-system-packages numpy pandas

# 添加 Go
RUN curl -OL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
```

**添加 VS Code 扩展** — 编辑 `devcontainer/devcontainer.json`：

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

然后重建：`Cmd+Shift+P` -> `Dev Containers: Rebuild Container`

---

## 包含什么？

| 类别         | 工具                            |
| ------------ | ------------------------------- |
| **运行时**    | Node.js 20、Python 3、npm、pip  |
| **编辑器**    | nano、vim                       |
| **搜索**      | ripgrep (`rg`)、fd-find         |
| **版本控制**  | git、gh (GitHub CLI)、git-delta |
| **Shell**    | zsh、Oh My Zsh、fzf             |
| **网络**      | curl、wget、jq                  |
| **安全**      | iptables、ipset、dnsutils       |

---

## 所有 CLI 选项

```text
用法：cc-sandboxer [project_path] [options]

参数：
  project_path              项目路径（默认：当前目录）

设置：
  --init                    在项目中创建 devcontainer + VS Code 任务
  --rebuild                 强制重建 Docker 镜像
  --update                  更新到最新版本并重建镜像
  --uninstall               删除镜像、volumes 和缓存
  --version, -v             显示版本
  --help, -h                显示帮助

运行时：
  --shell                   打开 shell 而不启动 Claude
  --no-firewall             跳过网络防火墙
  --allow-domain NAME       将域名加入白名单（可重复使用）
  --continue, -c            继续上次对话
  -p "prompt"               一次性任务模式
  --disallowedTools TOOLS   阻止特定的 Claude 工具
```

---

## 清理

```bash
# 一条命令 — 删除镜像、volumes 和缓存
cc-sandboxer --uninstall

# 同时卸载全局 npm 包
npm uninstall -g cc-sandboxer
```

或手动：

```bash
# 删除持久化数据
docker volume rm claude-config claude-npm claude-history

# 删除镜像
docker rmi cc-sandboxer:latest

# 删除 DevContainer volumes
docker volume rm claude-code-config claude-code-npm claude-code-history
```

---

## 故障排除

### "Firewall skipped"

容器需要 `NET_ADMIN` 权限。
CLI 模式下会自动设置。
DevContainer 模式下，检查 `devcontainer.json` 是否包含：

```json
"runArgs": ["--cap-add=NET_ADMIN"]
```

### Claude 未认证

```bash
# CLI 模式
./cc-sandboxer.sh --shell
claude login

# VS Code 模式
# Cmd+Shift+P -> Tasks: Run Task -> Claude: Login
```

### 首次构建很慢

首次构建需要下载 Node.js、系统包和 Claude Code（约2-3分钟）。
后续运行使用缓存镜像。
强制重建以更新 Claude Code：

```bash
./cc-sandboxer.sh --rebuild
# 或在 VS Code 中：
# Cmd+Shift+P -> Dev Containers: Rebuild Container
```

### 需要被阻止的域名

```bash
# CLI
./cc-sandboxer.sh --allow-domain "your-domain.com"

# DevContainer
# 添加到 init-firewall.sh 的 ALLOWED_DOMAINS 数组
# 或设置环境变量：
# EXTRA_ALLOWED_DOMAINS="domain1.com,domain2.com"
```

### VS Code 扩展在容器中不工作

打开扩展面板，找到该扩展，
然后点击 "Install in Container"。
部分扩展需要在 DevContainer 内手动安装。

---

## 测试

单元测试使用 [bats-core](https://github.com/bats-core/bats-core)（Bash 自动化测试系统）。

### 安装与运行

```bash
# 安装 bats（macOS）
brew install bats-core

# 运行所有测试
bats tests/

# 运行特定测试文件
bats tests/cc-sandbox.bats
bats tests/init-firewall.bats
```

### 测试覆盖

| 领域 | 测试数 | 覆盖内容 |
| --- | --- | --- |
| CLI 标志 | 5 | `--version`、`-v`、`--help`、`-h`、所有选项 |
| 域名验证 | 5 | 缺少参数、标志冲突、特殊字符、空格、斜杠 |
| `--init` 模式 | 10 | 文件创建、不覆盖、内容验证、源同步 |
| 防火墙生成 | 7 | 默认/额外域名、iptables 规则、DNS 隧道、SSH、语法 |
| 防火墙脚本 | 19 | 语法、域名、安全规则、ipset 排序、正则验证 |
| 显示 | 3 | 横幅、版本字符串、ASCII art |
| **总计** | **49** | |

---

## 贡献

欢迎 PR！一些想法：

- [ ] 添加 Cursor IDE 支持
- [ ] 添加 Windsurf 支持
- [ ] 按项目配置防火墙

---

## 许可证

MIT — 详见 [LICENSE](LICENSE)。

---

**为喜欢把 `rm -rf` 关在笼子里的开发者而建。**

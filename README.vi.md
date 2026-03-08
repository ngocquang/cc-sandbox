# Claude Code Sandbox

[English](README.md) | **Tiếng Việt** | [中文](README.zh.md)

```text
       ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
      ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
      ██║     ██║     ███████║██║   ██║██║  ██║█████╗
      ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝
      ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
       ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
                C O D E   S A N D B O X
```

**Chạy `claude --dangerously-skip-permissions` an toàn trong Docker sandbox.**

Một lệnh duy nhất. Cách ly hoàn toàn. Terminal hoặc VS Code.

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

## Bắt đầu nhanh

### Qua npx (khuyên dùng)

```bash
# Chạy trong thư mục hiện tại
npx cc-sandboxer

# Chạy với dự án cụ thể
npx cc-sandboxer ~/projects/my-app

# Chạy một lệnh duy nhất
npx cc-sandboxer . -p "Sửa tất cả lỗi lint"

# Thiết lập VS Code DevContainer
npx cc-sandboxer --init ~/projects/my-app
```

### Qua git clone

```bash
git clone https://github.com/ngocquang/cc-sandbox.git
cd cc-sandbox
chmod +x cc-sandboxer.sh
./cc-sandboxer.sh
```

### VS Code (DevContainer)

```bash
# Thiết lập DevContainer trong dự án
npx cc-sandboxer --init ~/projects/my-app

# Mở VS Code -> Reopen in Container -> Chạy task
code ~/projects/my-app
```

> Lần chạy đầu tiên sẽ build Docker image (~2-3 phút). Sau đó, khởi động chỉ mất vài giây.

---

## Tại sao cần Sandbox?

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) với `--dangerously-skip-permissions` rất hiệu quả — Claude có thể thực thi **bất kỳ** lệnh nào mà không cần xác nhận. Nhưng chạy trực tiếp trên máy thật rất rủi ro:

|              | Không có Sandbox             | Có Sandbox                      |
| ------------ | ---------------------------- | ------------------------------- |
| Hệ thống tệp| Toàn quyền truy cập máy      | Chỉ `/workspace`                |
| Mạng         | Internet không giới hạn       | Chỉ domain trong whitelist      |
| TCP đi ra    | Mở tất cả cổng               | Chặn TCP không trong whitelist  |
| Trường hợp xấu nhất | `rm -rf /` phá hủy hệ thống | Container chết, máy host vẫn ổn |
| Overhead     | Không                         | ~3 giây                         |

---

## Cài đặt

### Cách A — npx (không cần cài)

```bash
npx cc-sandboxer
```

### Cách B — Cài toàn cục

```bash
npm install -g cc-sandboxer
cc-sandboxer
```

### Cách C — Clone repo

```bash
git clone https://github.com/ngocquang/cc-sandbox.git
cd cc-sandbox
chmod +x cc-sandboxer.sh
./cc-sandboxer.sh
```

### Alias cho Shell (tùy chọn)

Thêm vào `~/.zshrc` hoặc `~/.bashrc` để truy cập nhanh:

```bash
alias cc="npx cc-sandboxer"
```

Sau đó tải lại shell:

```bash
source ~/.zshrc
```

Bây giờ bạn có thể dùng:

```bash
cc                          # thư mục hiện tại
cc ~/projects/my-app        # dự án cụ thể
cc . -p "Sửa tất cả lỗi lint"
cc . --continue
```

### Yêu cầu hệ thống

Bạn cần **một** trong các container runtime sau:

> **Lưu ý:** Chỉ hỗ trợ **macOS** và **Linux**. Không hỗ trợ Windows.

| Runtime        | Nền tảng       | Cài đặt                                                       |
| -------------- | -------------- | ------------------------------------------------------------- |
| Docker Desktop | macOS / Linux  | [docker.com](https://www.docker.com/products/docker-desktop/) |
| OrbStack       | macOS          | [orbstack.dev](https://orbstack.dev/)                         |
| Colima         | macOS / Linux  | [github](https://github.com/abiosoft/colima)                  |
| Docker Engine  | Linux          | [docs.docker.com](https://docs.docker.com/engine/install/)    |

Với chế độ VS Code, cần cài thêm extension [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

---

## Chế độ Terminal

### Tương tác (khuyên dùng)

```bash
cc-sandboxer                     # thư mục hiện tại
cc-sandboxer ~/projects/my-app   # dự án cụ thể
```

### Chạy lệnh một lần

```bash
cc-sandboxer . -p "Tái cấu trúc module auth và viết test"
cc-sandboxer . -p "Sửa tất cả lỗi ESLint và thêm type còn thiếu"
cc-sandboxer . -p "Đọc SPEC.md -> viết test fail -> implement -> lặp lại"
```

### Tiếp tục cuộc hội thoại trước

```bash
cc-sandboxer . --continue
```

### Chặn lệnh nguy hiểm

```bash
cc-sandboxer . --disallowedTools "Bash(rm:*)"
```

### Chế độ shell

```bash
cc-sandboxer --shell
# Sau đó chạy thủ công bên trong:
#   claude --dangerously-skip-permissions
```

> Tất cả lệnh hoạt động với `npx cc-sandboxer`, `cc-sandboxer` (cài toàn cục), hoặc `./cc-sandboxer.sh` (clone repo).

---

## Chế độ VS Code

Flag `--init` thiết lập môi trường DevContainer đầy đủ trong dự án — không cần cấu hình thủ công.

### Thiết lập

```bash
./cc-sandboxer.sh --init ~/projects/my-app
```

Lệnh này tạo ra:

```text
your-project/
├── devcontainer/
│   ├── Dockerfile             # Image sandbox với đầy đủ công cụ
│   ├── devcontainer.json      # Cấu hình container cho VS Code
│   └── init-firewall.sh       # Quy tắc bảo mật mạng
└── .vscode/
    └── tasks.json             # Task Claude được cấu hình sẵn
```

### Khuyên dùng: Cài Extension Claude Code

Để có trải nghiệm tốt nhất trong DevContainer, hãy cài [extension Claude Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) trong VS Code **trước khi** mở container. DevContainer đã được cấu hình sẵn để tự động cài extension bên trong container, nhưng cài trên máy host giúp thiết lập mượt mà hơn.

> **Mẹo:** Extension cung cấp giao diện VS Code tích hợp cho Claude Code — bảng chat, gợi ý inline và quản lý task — tất cả đều trong sandbox.

### Mở trong VS Code

```text
1.  code ~/projects/my-app
2.  Cmd+Shift+P -> "Dev Containers: Reopen in Container"
3.  Đợi build (chỉ lần đầu)
4.  Extension Claude Code tự động cài trong container.
5.  Xong! Bạn đã ở trong sandbox.
```

### Task trong VS Code

Khi đã ở trong container, dùng `Cmd+Shift+P` -> `Tasks: Run Task`:

| Task                      | Mô tả                            |
| ------------------------- | --------------------------------- |
| Claude: Skip Permissions  | Chế độ tương tác                   |
| Claude: Resume Last Chat  | Tiếp tục cuộc hội thoại trước     |
| Claude: One-Shot Task     | Nhập mô tả task cần thực hiện     |
| Claude: Safe Mode (no rm) | Bỏ qua quyền nhưng chặn `rm`      |
| Firewall: Re-initialize   | Áp dụng lại quy tắc mạng          |
| Claude: Login             | Xác thực lần đầu                   |

### Xác thực lần đầu

```bash
# Chạy task login, hoặc trong terminal:
claude login
```

Token xác thực được lưu trong Docker volume — bạn chỉ cần làm một lần.

---

## Bảo mật

### Tường lửa mạng

Container chạy tường lửa `iptables` với **chặn mặc định tất cả TCP đi ra**. Chỉ các domain trong whitelist được phép:

| Dịch vụ        | Domain                                                             |
| -------------- | ------------------------------------------------------------------ |
| Claude API     | `api.anthropic.com`, `auth.anthropic.com`, `statsig.anthropic.com`, `sentry.io`, `anthropic.gallerycdn.azure.cn` |
| Claude Code    | `storage.googleapis.com`                                           |
| npm            | `registry.npmjs.org`, `registry.yarnpkg.com`                       |
| GitHub         | `github.com`, `api.github.com`, `*.githubusercontent.com`          |
| PyPI           | `pypi.org`, `files.pythonhosted.org`                               |
| Microsoft      | `microsoft.com`                                                    |
| VS Code        | `marketplace.visualstudio.com`, `open-vsx.org`, `*.vo.msecnd.net`, `gallerycdn.vsassets.io` |

**Mọi thứ khác đều bị chặn.** Claude không thể rò rỉ code hoặc tải từ nguồn không tin cậy.

Tính năng bảo mật chính:

- **Chặn tất cả TCP đi ra** mặc định (không chỉ port 80/443)
- **Giảm thiểu DNS tunneling** — truy vấn DNS chỉ giới hạn ở resolver cục bộ
- **Xác thực đầu vào** — tên domain được kiểm tra trước khi thêm vào whitelist
- **Không dùng seccomp=unconfined** — chỉ cấp capability `NET_ADMIN` cho iptables

#### Thêm domain tùy chỉnh

```bash
# Chế độ CLI
./cc-sandboxer.sh --allow-domain "api.example.com" --allow-domain "docker.io"

# Chế độ DevContainer — sửa devcontainer/init-firewall.sh
# Hoặc đặt biến môi trường trong devcontainer.json:
#   "containerEnv": { "EXTRA_ALLOWED_DOMAINS": "api.example.com,docker.io" }
```

### Cách ly hệ thống tệp

| Mục             | Quyền truy cập            |
| --------------- | ------------------------- |
| Dự án của bạn   | Mount tại `/workspace`    |
| Hệ thống host   | Cách ly                   |
| `.gitconfig`    | Chỉ đọc                  |
| Token xác thực  | Docker volume (lưu trữ)   |

---

## Cấu hình

### Biến môi trường

| Biến                    | Mặc định           | Mô tả                                              |
| ----------------------- | ------------------- | --------------------------------------------------- |
| `TZ`                    | `Asia/Ho_Chi_Minh`  | Múi giờ container                                   |
| `EXTRA_ALLOWED_DOMAINS` | _(trống)_           | Domain cách nhau bởi dấu phẩy cho tường lửa (DevContainer) |

```bash
TZ=America/New_York ./cc-sandboxer.sh
```

### Tùy chỉnh DevContainer

Sau khi chạy `--init`, bạn có thể sửa bất kỳ file nào trong `devcontainer/`:

**Thêm công cụ** — sửa `devcontainer/Dockerfile`:

```dockerfile
# Thêm công cụ Python ML
RUN pip3 install --break-system-packages numpy pandas

# Thêm Go
RUN curl -OL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
```

**Thêm extension VS Code** — sửa `devcontainer/devcontainer.json`:

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

Sau đó rebuild: `Cmd+Shift+P` -> `Dev Containers: Rebuild Container`

---

## Có gì trong hộp?

| Danh mục     | Công cụ                         |
| ------------ | ------------------------------- |
| **Runtime**  | Node.js 20, Python 3, npm, pip  |
| **Editor**   | nano, vim                       |
| **Tìm kiếm**| ripgrep (`rg`), fd-find         |
| **VCS**      | git, gh (GitHub CLI), git-delta |
| **Shell**    | zsh, Oh My Zsh, fzf             |
| **Mạng**     | curl, wget, jq                  |
| **Bảo mật**  | iptables, ipset, dnsutils       |

---

## Tất cả tùy chọn CLI

```text
Cách dùng: cc-sandboxer [project_path] [options]

Tham số:
  project_path              Đường dẫn đến dự án (mặc định: thư mục hiện tại)

Thiết lập:
  --init                    Tạo devcontainer + VS Code tasks trong dự án
  --rebuild                 Buộc build lại Docker image
  --update                  Cập nhật lên phiên bản mới nhất & build lại image
  --uninstall               Xóa image, volumes & cache
  --version, -v             Hiển thị phiên bản
  --help, -h                Hiển thị trợ giúp

Runtime:
  --shell                   Mở shell mà không khởi động Claude
  --no-firewall             Bỏ qua tường lửa mạng
  --allow-domain NAME       Thêm domain vào whitelist (có thể lặp lại)
  --continue, -c            Tiếp tục cuộc hội thoại trước
  -p "prompt"               Chế độ chạy lệnh một lần
  --disallowedTools TOOLS   Chặn các tool cụ thể của Claude
```

---

## Dọn dẹp

```bash
# Một lệnh — xóa image, volumes, cache & package npm global
cc-sandboxer --uninstall
```

Hoặc thủ công:

```bash
# Xóa dữ liệu lưu trữ
docker volume rm claude-config claude-npm claude-history

# Xóa image
docker rmi cc-sandboxer:latest

# Xóa volume DevContainer
docker volume rm claude-code-config claude-code-npm claude-code-history
```

---

## Xử lý sự cố

### "Firewall skipped"

Container cần capability `NET_ADMIN`.
Trong chế độ CLI, điều này được thiết lập tự động.
Trong chế độ DevContainer, kiểm tra `devcontainer.json` có:

```json
"runArgs": ["--cap-add=NET_ADMIN"]
```

### Claude chưa xác thực

```bash
# Chế độ CLI
./cc-sandboxer.sh --shell
claude login

# Chế độ VS Code
# Cmd+Shift+P -> Tasks: Run Task -> Claude: Login
```

### Lần build đầu chậm

Lần build đầu tải Node.js, system packages và Claude Code (~2-3 phút).
Các lần chạy sau dùng image đã cache.
Buộc build lại để cập nhật Claude Code:

```bash
./cc-sandboxer.sh --rebuild
# hoặc trong VS Code:
# Cmd+Shift+P -> Dev Containers: Rebuild Container
```

### Cần domain bị chặn

```bash
# CLI
./cc-sandboxer.sh --allow-domain "your-domain.com"

# DevContainer
# thêm vào mảng ALLOWED_DOMAINS trong init-firewall.sh
# hoặc đặt biến môi trường:
# EXTRA_ALLOWED_DOMAINS="domain1.com,domain2.com"
```

### Extension VS Code không hoạt động trong container

Mở bảng Extensions, tìm extension,
sau đó nhấn "Install in Container".
Một số extension cần được cài thủ công
bên trong DevContainer.

---

## Kiểm thử

Unit test dùng [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

### Cài đặt & Chạy

```bash
# Cài bats (macOS)
brew install bats-core

# Chạy tất cả test
bats tests/

# Chạy file test cụ thể
bats tests/cc-sandbox.bats
bats tests/init-firewall.bats
```

### Phạm vi kiểm thử

| Lĩnh vực | Số test | Nội dung kiểm tra |
| --- | --- | --- |
| CLI flags | 5 | `--version`, `-v`, `--help`, `-h`, tất cả tùy chọn |
| Xác thực domain | 5 | Thiếu tham số, xung đột flag, ký tự đặc biệt, khoảng trắng, dấu gạch |
| Chế độ `--init` | 10 | Tạo file, không ghi đè, xác thực nội dung, đồng bộ nguồn |
| Sinh firewall | 7 | Domain mặc định/thêm, quy tắc iptables, DNS tunneling, SSH, cú pháp |
| Script firewall | 19 | Cú pháp, domain, quy tắc bảo mật, thứ tự ipset, xác thực regex |
| Hiển thị | 3 | Banner, chuỗi phiên bản, ASCII art |
| **Tổng** | **49** | |

---

## Đóng góp

PR luôn được chào đón! Một số ý tưởng:

- [ ] Hỗ trợ Cursor IDE
- [ ] Hỗ trợ Windsurf
- [ ] Cấu hình firewall theo dự án

---

## Giấy phép

MIT — xem [LICENSE](LICENSE) để biết chi tiết.

---

**Được xây dựng cho lập trình viên thích giữ `rm -rf` trong tầm kiểm soát.**

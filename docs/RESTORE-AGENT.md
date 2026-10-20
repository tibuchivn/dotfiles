# RESTORE FOR AGENTS — runbook cho agent khác

Mục tiêu: dựng lại máy macOS dev từ repo dotfiles + backup trên Google Drive.
Bạn là agent đang chạy trên **máy mới**; người dùng ngồi cạnh và có thể gõ passphrase,
đăng nhập app, cắm thiết bị.

Đọc hết file này trước khi chạy bất kỳ lệnh nào.

---

## 0. Sự thật nền (không cần đoán lại)

| Thứ | Giá trị |
|---|---|
| Máy nguồn | macOS 15.7.7, arm64, Homebrew prefix `/opt/homebrew` |
| Repo | `git@github-tibuchivn:tibuchivn/dotfiles.git`, branch `backup/pre-reset-2026-10-20` |
| Backup | folder Drive `backup-mac-2026-10-20`, tải về `~/backup-2026-10-20` |
| Entry point | `~/tung/dotfiles/bin/restore.sh` — 12 bước, có `--step` và `--dry-run` |
| Secrets | `10-secrets/secrets-YYYYMMDD.tar.gz.age` — passphrase **chỉ người dùng biết** |
| Tổng backup | ~1.7GB (mysql dump 1.5GB là phần lớn nhất) |

## 1. Luật cứng

1. **Không bao giờ hỏi, ghi lại, hay tự sinh passphrase/token.** Người dùng tự chạy `age -d`
   và tự đăng nhập. Bạn không được đưa passphrase vào lệnh, file, hay chat.
2. **`bash -n` trước khi chạy mọi script sinh ra.** Một lỗi syntax trong thân hàm bash có thể
   khiến phần còn lại của file được thực thi như lệnh top-level — đã từng gây `bun add -g`
   cho ~400 package. Đừng lặp lại: kiểm tra syntax, chạy `--dry-run`, rồi mới chạy thật.
3. **Không xoá/di chuyển file có sẵn của người dùng** mà không đổi tên thành
   `*.pre-restore-<stamp>`.
4. **Không tự apply macOS defaults**, không cài app MDM (Company Portal, JamfProtect,
   Defender), không đăng nhập hộ.
5. **Báo cáo output thật.** Bước nào fail thì dừng, báo rõ lệnh + lỗi, không chạy tiếp "cho xong".
6. **Không push/không rewrite git history** của người dùng.

## 2. Chia việc

| Việc | Ai làm |
|---|---|
| Cài Xcode CLT, Homebrew, age, zstd | agent (có thể cần người dùng nhập password admin) |
| Tải backup từ Drive | người dùng (hoặc agent nếu đã mount) |
| Giải mã secrets | **người dùng** (agent chỉ đưa lệnh) |
| Clone repo, symlink, restore state, import DB | agent |
| Login app, MDM, license, keychain, VPN | người dùng |
| Xác nhận cuối | agent chạy checklist, người dùng xác nhận app chạy được |

## 3. Các bước (có gate, đừng nhảy cóc)

### B1 — Bootstrap tool
```bash
xcode-select -p || xcode-select --install
brew --version || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install age zstd git
```
Gate: `age --version`, `zstd --version`, `git --version` đều trả về số version.

### B2 — Lấy backup (1.7GB)
Đường dẫn Drive: `~/Library/CloudStorage/GoogleDrive-<account>/My Drive/backup-mac-2026-10-20`.
Nếu mount chết (`ls` timeout 30s), bảo người dùng tải qua web rồi giải nén về `~/backup-2026-10-20`.

Gate:
```bash
cd ~/backup-2026-10-20
shasum -a 256 -c SHA256SUMS
```
Kỳ vọng: 13 dòng `OK` cho `10-secrets/*.age`, `20-state/*.tar.zst` (gồm `tools-config`),
`30-db/*`.
Các dòng `FAILED open or read` cho `10-secrets/bundle/...` là **bình thường** (bundle plaintext
đã bị xoá trước khi reset, không upload).

### B3 — Giải mã secrets (NGƯỜI DÙNG chạy)
Đưa người dùng đúng lệnh này, không tự chạy:
```bash
cd ~/backup-2026-10-20/10-secrets
mkdir -p bundle
age -d secrets-20261020.tar.gz.age | tar -xzf - -C bundle
chmod -R go-rwx bundle
```
Gate: `ls bundle` phải thấy `ssh/ zsh_secrets etc/ gnupg/ hermes/ kubeconfigs/`.

### B4 — SSH key + ssh config TRƯỚC, rồi mới clone (git config chưa cần)

`git clone` qua SSH cần đúng 3 thứ, **không cần `~/.gitconfig`**:
`~/.ssh/config` (có `Host github-tibuchivn`), private key đúng file, và quyền 600.
`user.name/user.email` chỉ cần khi commit — có sau bước `link` (symlink `~/.gitconfig`).

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
rsync -a ~/backup-2026-10-20/10-secrets/bundle/ssh/ ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/*_rsa ~/.ssh/*.pem 2>/dev/null
chmod 644 ~/.ssh/*.pub ~/.ssh/config ~/.ssh/known_hosts 2>/dev/null
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh-add --apple-use-keychain ~/.ssh/id_rsa_tibuchivn

# GATE bắt buộc — phải qua trước khi clone:
ssh -T git@github-tibuchivn     # kỳ vọng: "Hi <user>! You've successfully authenticated"
```

Nếu gate fail: kiểm tra `ssh -v git@github-tibuchivn`, xem `~/.ssh/config` có block
`Host github-tibuchivn` + `IdentityFile ~/.ssh/id_rsa_tibuchivn`, và key có mode 600.
Không được "clone bằng cách khác" rồi bỏ qua — báo người dùng.

Fallback khi SSH không thể sửa (ví dụ key hỏng): tải zip branch
`backup/pre-reset-2026-10-20` từ GitHub web, giải nén vào `~/tung/dotfiles`;
`bin/restore.sh` không cần `.git` để chạy, chỉ mất khả năng `git pull/commit`.

SSH config trong bundle dùng `IdentityFile ~/.ssh/...` (portable, không phụ thuộc username).
Dòng `Include ~/.colima/ssh_config` có thể trỏ file không tồn tại trên máy mới — vô hại.

```bash
mkdir -p ~/tung
git clone git@github-tibuchivn:tibuchivn/dotfiles.git ~/tung/dotfiles
cd ~/tung/dotfiles && git checkout backup/pre-reset-2026-10-20
```
Gate: `git log --oneline -1` ra commit `feat(dotfiles): track full config set...` hoặc mới hơn.

### B5 — Chạy restore theo từng bước
```bash
cd ~/tung/dotfiles
bash -n bin/restore.sh        # PHẢI không in gì
./bin/restore.sh --dry-run    # xem thứ tự 12 bước
./bin/restore.sh --step prereq
./bin/restore.sh --step brew  # lâu nhất: ~175 formula + 40 cask, 20-60 phút
```
Sau `brew`, chạy tiếp từng bước một và đọc output:

| Bước | Làm gì | Gate |
|---|---|---|
| `secrets` | copy ssh/gnupg/aws/kube/gh/zsh_secrets từ bundle | `zsh -ic 'echo ${#DEEPSEEK_API_KEY}'` > 0 |
| `link` | symlink config tĩnh | `readlink ~/.zshrc` trỏ vào repo |
| `state` | giải nén claude/hermes/opencode + tools-config | `ls ~/.claude/settings.json`, `~/.hermes/state.db`, VS Code `settings.json` |
| `toolchains` | asdf/mise/uv/gem/bun | `asdf current`, `node -v` |
| `services` | start mysql@8.0, postgresql@14, redis | `brew services list` thấy `started` |
| `db` | import mysql (10-20 phút) + pg | `mysql -uroot -e 'show databases'` |
| `nvim` | Lazy restore + Mason | mở `nvim` không lỗi |
| `tmux` | tpm install_plugins | `tmux new -d && tmux ls` |
| `hermes` | cài Hermes Agent — **no-op nếu đã có** (agent đang chạy chính nó thì đúng là đã có) | `hermes --version` |
| `hermes-import` | `hermes import --force` từ `hermes-native-backup.zip` (tự snapshot `~/.hermes` trước) | `hermes doctor` không báo lỗi config |
| `claude` | cài Claude Code | `claude --version` |

`mysql` import dài: chạy nền và theo dõi, đừng để timeout im lặng.

### B6 — Verify (bắt buộc, chạy hết)
```bash
ls -l ~/.zshrc ~/.tmux.conf ~/.gitconfig ~/.config/nvim    # tất cả là symlink
git -C ~/tung/dotfiles status --short                       # phải trống
brew bundle check --file ~/tung/dotfiles/Brewfile
mysql -uroot -e 'select count(*) from information_schema.tables where table_schema="tinypulse_development";'
# kỳ vọng: 379
psql -l | head
nvim --headless "+Lazy! check" +qa
zsh -ic 'echo $PATH' | tr ':' '\n' | head -5
```
So `docs/manifests/` với máy thật: `brew-leaves.txt`, `vscode-extensions.txt`,
`user-fonts.txt`, `applications.txt`.

### B7 — Phần tay (bàn giao cho người dùng)
- App ngoài brew: `docs/manifests/applications.txt` (82 app, ~35 không có cask) + MDM enrollment.
- VS Code: `cat docs/manifests/vscode-extensions.txt | xargs -n1 code --install-extension`
- Font thiếu: so `docs/manifests/user-fonts.txt` với `~/Library/Fonts`.
- macOS defaults: `docs/manifests/macos-defaults.txt` chỉ để tham khảo.
- Hermes gateway: `cp ~/backup-2026-10-20/40-apps/launchagents/*.plist ~/Library/LaunchAgents/`
  rồi `launchctl load ...` — chỉ sau khi `hermes` đã login.
- Docker: `brew install colima docker && colima start`; Ollama: `ollama pull <model>`.
- Keychain / Touch ID / FileVault / VPN / license: người dùng.

## 4. Bẫy đã gặp (đừng mất thời gian phát hiện lại)

- **Config tĩnh = symlink, config app tự ghi = copy snapshot.** Claude/opencode/hermes ghi
  settings bằng temp+rename nên sẽ phá symlink. Đừng "sửa" bằng cách symlink chúng.
- **`~/.gitconfig` trong repo có `trace2.eventTarget` trỏ socket của Asterix.app**
  (`/Users/ttram/.corp-tool/...`). Máy mới chưa có app đó → git vẫn chạy, chỉ mất trace.
  Nếu git phàn nàn: `git config --global --unset trace2.eventtarget`.
- **Đừng giải nén `hermes-state.tar.zst` đè lên bản Hermes vừa cài.** Hermes có lệnh native:
  `hermes backup` (zip, không gồm codebase) và `hermes import --force <zip>`.
  `hermes import` an toàn cả khi Hermes đang chạy: nó ghi `.db` qua SQLite backup API (không thay
  inode) và bỏ qua `gateway.pid`/`*.lock`/`gateway_state.json` của máy nguồn. Nhưng config/memory/
  skills chỉ được nạp lúc khởi động → **phải restart session Hermes sau khi import**.
  Chạy import dưới đúng home mặc định (`~/.hermes`), không chạy trong một profile, kẻo nó
  restore vào `profiles/<name>`. Version lệch thì `hermes doctor` rồi `hermes migrate`.
- **`.claude/settings.json` trong repo đã sanitize**: token bị thay bằng `REPLACE_ME`.
  Giá trị thật nằm trong `bundle/claude-disabled-env.txt`. Chỉ khôi phục nếu người dùng cần
  gateway đó; đây là token của key `_DISABLED_*` nên thường không cần.
- **`brew bundle` có thể fail vài tap** (`elastic/tap`, `heroku/brew`, formula cũ đã bỏ).
  Đọc output, cài bù bằng tay, đừng coi là hỏng toàn bộ.
- **asdf**: shim có thể báo `exec: asdf: not found` nếu PATH thiếu `/opt/homebrew/bin`.
  Chạy `asdf plugin add` cho từng plugin trong `~/.tool-versions` rồi `asdf install`.
- **MySQL dump**: verify bằng `gunzip -c ... | tail -1` phải có `-- Dump completed`, và đếm
  `^CREATE TABLE` = 770, `^CREATE DATABASE` = 4.
- **Drive File Provider hay treo** 30s+: `timeout 30 ls "<mount>/My Drive"` trước khi hứa copy.
- **Không có Time Machine** trên máy cũ; đừng giả định có snapshot để rollback.
- **8/9 SSH key không passphrase** — sau restore nên đề nghị `ssh-keygen -p -f ~/.ssh/<key>`.
- **`~/.hermes` trong archive không có binary** (`hermes-agent/`, `tools/`, `node/`, `cache/` bị
  loại) — phải cài lại bằng installer, đừng đi tìm.

## 5. Definition of done

- [ ] `shasum -a 256 -c SHA256SUMS` trong backup: 12 OK
- [ ] `git -C ~/tung/dotfiles status --short` trống, đúng branch
- [ ] mọi symlink trong `bin/link.sh` trỏ đúng vào repo
- [ ] `zsh -ic` load được `DEEPSEEK_API_KEY`, `brew`, `nvim`, `tmux`
- [ ] `mysql`: 4 DB, `tinypulse_development` 379 bảng
- [ ] `postgres`: 3 DB test
- [ ] `hermes --version`, `claude --version`, `opencode --version` chạy
- [ ] `nvim` mở không lỗi plugin, `tmux` tạo session được
- [ ] người dùng xác nhận: đăng nhập được GitHub, Drive, Bitwarden, VPN

Nếu bước nào không đạt: báo rõ bước, lệnh, output, và phần nào của backup cần tải lại —
đừng tự đoán mò hay sửa file config của người dùng cho "chạy được".

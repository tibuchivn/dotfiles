# RESTORE — dựng lại máy sau khi reset

Backup tạo ngày 2026-10-20. Gồm 2 phần:

> Nếu bạn là **agent** được giao restore: đọc `docs/RESTORE-AGENT.md` (runbook có gate,
> chia việc agent/người dùng, và danh sách bẫy). File này dành cho người đọc.

| Phần | Ở đâu | Chứa gì |
|---|---|---|
| Config | repo này (`~/tung/dotfiles`) | zsh, tmux, git, nvim, alacritty, kitty, hammerspoon, opencode, claude, hermes config, Brewfile, manifests |
| State + secrets | `~/backup-2026-10-20/` | secrets (age-encrypted), claude/hermes/opencode state, DB dumps |

Trước khi reset máy, đọc hết mục **Checklist trước reset** ở cuối.

---

## 0. Chuẩn bị (máy mới)

```bash
xcode-select --install                                  # Xcode CLT
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install age git zstd
```

Khôi phục secrets trước (cần cho SSH key để clone repo):

```bash
# tải secrets-YYYYMMDD.tar.gz.age từ Google Drive về ~/backup-2026-10-20/10-secrets/
mkdir -p ~/backup-2026-10-20/10-secrets/bundle
age -d secrets-YYYYMMDD.tar.gz.age | tar -xzf - -C ~/backup-2026-10-20/10-secrets/bundle
```

## 1. Clone repo

```bash
mkdir -p ~/tung
git clone git@github-tibuchivn:tibuchivn/dotfiles.git ~/tung/dotfiles
```

> Nếu chưa có SSH key: copy `~/.ssh/id_ed25519` + `id_ed25519.pub` từ bundle trước
> (`rsync -a ~/backup-2026-10-20/10-secrets/bundle/ssh/ ~/.ssh/ && chmod 600 ~/.ssh/id_*`),
> rồi `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`.

Tải phần state về đúng chỗ:

```bash
# ~/backup-2026-10-20/20-state/*.tar.zst   (claude, hermes, opencode, alacritty themes, tmux plugins)
# ~/backup-2026-10-20/30-db/*              (mysql .sql.gz, postgres .dump, redis dump.rdb)
```

## 2. Chạy một lệnh

```bash
cd ~/tung/dotfiles
./bin/restore.sh --dry-run          # xem thứ tự các bước
./bin/restore.sh                    # chạy toàn bộ
```

Từng bước riêng (khi cần chạy lại):

```bash
./bin/restore.sh --step brew        # brew bundle install (lâu nhất, ~175 formula + 40 cask)
./bin/restore.sh --step secrets
./bin/restore.sh --step link        # symlink config tĩnh
./bin/restore.sh --step state       # giải nén claude/hermes/opencode
./bin/restore.sh --step toolchains  # asdf / mise / uv / gem / bun
./bin/restore.sh --step services    # mysql, postgres, redis
./bin/restore.sh --step db          # import dump (~10-20 phút cho mysql)
./bin/restore.sh --step nvim
./bin/restore.sh --step tmux
./bin/restore.sh --step hermes
./bin/restore.sh --step claude
```

## 3. Kiểm tra sau khi restore

```bash
zsh -ic 'echo $DEEPSEEK_API_KEY | wc -c'      # phải > 0
ls -l ~/.zshrc ~/.tmux.conf ~/.gitconfig       # phải là symlink vào ~/tung/dotfiles
git -C ~/tung/dotfiles status                   # phải sạch
ssh -T git@github.com                           # phải nhận diện đúng account
brew bundle check --file ~/tung/dotfiles/Brewfile
mysql -uroot -e 'show databases'
psql -l | head
nvim --headless "+Lazy! check" +qa 2>/dev/null || true
```

## 4. Làm tay (không tự động được)

- **App ngoài brew**: xem `docs/manifests/applications.txt`. Các app MDM (Company Portal,
  JamfProtect, Microsoft Defender) phải enroll lại qua IT.
- **Đăng nhập**: Bitwarden, iCloud, Google, Slack/Teams, VPN (FortiClient/Azure VPN),
  Ollama, Claude/Codex/Gemini CLI.
- **VS Code extension**: `docs/manifests/vscode-extensions.txt`
  → `cat docs/manifests/vscode-extensions.txt | xargs -n1 code --install-extension`
- **Font**: so `docs/manifests/user-fonts.txt` với `~/Library/Fonts`; cask font đã cài qua Brewfile.
- **macOS defaults**: `docs/manifests/macos-defaults.txt` để tham khảo (không auto-apply).
- **Hermes gateway**: `cp ~/backup-2026-10-20/40-apps/launchagents/*.plist ~/Library/LaunchAgents/`
  rồi `launchctl load ...` sau khi đã `hermes` login.
- **Docker**: `brew install colima docker && colima start` (image pull lại).
- **Ollama models**: `ollama pull <model>` — không backup (4.2G).
- **Karabiner/keychain/Touch ID/FileVault**: theo máy mới.

## Ghi chú thiết kế

- Config **tĩnh** (zsh, tmux, git, nvim, alacritty, kitty, hammerspoon, starship, mise)
  là **symlink** `$HOME → repo`. Sửa trực tiếp trong repo là có hiệu lực ngay.
- Config **app tự ghi** (opencode, claude, hermes) là **snapshot copy**, không symlink —
  vì các app này ghi file bằng rename, sẽ phá symlink. Làm mới snapshot:
  `./bin/sync.sh` rồi commit.
- **Secrets** không bao giờ vào git: `~/.zsh_secrets` (gitignored) + bundle age-encrypted.
- File `.zshrc` gốc đã tách API key sang `~/.zsh_secrets`; mẫu ở `.zsh_secrets.example`.

## Checklist trước reset

- [ ] `./bin/sync.sh` + `git -C ~/tung/dotfiles add -A && git commit` (chụp config mới nhất)
- [ ] `git -C ~/tung/dotfiles push` (branch `backup/pre-reset-2026-10-20`)
- [ ] Chạy `10-secrets/encrypt-secrets.sh` (tự nhập passphrase, lưu passphrase vào Bitwarden)
- [ ] Upload `10-secrets/*.age`, `20-state/*.tar.zst`, `30-db/*` lên Google Drive
- [ ] `shasum -a 256` các file backup, lưu `SHA256SUMS` (script `verify.sh` trong backup dir)
- [ ] Xác nhận DB dump: `gunzip -c 30-db/mysql-user-dbs.sql.gz | tail -1` → "Dump completed"
- [ ] Đăng xuất các app có license gắn máy (JetBrains, TablePlus, Lens...) để giải phóng seat
- [ ] Xoá plaintext `10-secrets/bundle/` sau khi đã mã hoá + upload

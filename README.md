# dotfiles

Dotfiles + backup/restore cho máy macOS (arm64, /opt/homebrew).

## Cấu trúc

- Config **tĩnh** → symlink `$HOME` vào repo: `bin/link.sh`
  (zsh, tmux, git, nvim/nvim_bk/jev, alacritty, kitty, starship, mise, hammerspoon)
- Config **app tự ghi** (opencode, claude, hermes) → snapshot copy: `bin/sync.sh`
- Cài lại toàn bộ máy mới → `bin/restore.sh` (xem `docs/RESTORE.md`)
- Secrets **không** nằm trong repo: `~/.zsh_secrets` (gitignored), bundle age-encrypted riêng

## Lệnh thường dùng

```bash
./bin/link.sh                 # tạo symlink (idempotent)
./bin/sync.sh                 # chụp lại config opencode/claude/hermes vào repo
./bin/restore.sh --dry-run    # xem thứ tự restore
./bin/restore.sh              # restore máy mới
```

## Brew

```bash
brew bundle dump --force --file=Brewfile   # cập nhật Brewfile
brew bundle install --file=Brewfile
brew bundle check --file=Brewfile
```

## Manifests

`docs/manifests/` chứa danh sách để cài lại: brew leaves/services, asdf/mise versions,
uv/gem/bun global, VS Code extensions, fonts, /Applications, macOS defaults, tmux plugins.

## Nguồn

- Hammerspoon: https://github.com/ashfinal/awesome-hammerspoon
- Tmux: https://github.com/gpakosz/.tmux
- Symlink guide: https://medium.com/free-code-camp/dive-into-dotfiles-part-2-6321b4a73608

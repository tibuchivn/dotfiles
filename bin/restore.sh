#!/usr/bin/env bash
# restore.sh — khôi phục máy mới từ repo dotfiles + backup archive.
#
# Chuẩn bị trước khi chạy:
#   1. Cài Xcode CLT + Homebrew
#   2. Clone repo:  git clone <repo> ~/tung/dotfiles   (cần SSH key, xem bước 2 bên dưới)
#   3. Giải mã secrets:  age -d -o secrets.tar.gz ~/backup-2026-10-20/10-secrets/secrets-*.age
#                        mkdir -p ~/backup-2026-10-20/10-secrets/bundle
#                        tar -xzf secrets.tar.gz -C ~/backup-2026-10-20/10-secrets/bundle
#   4. Chạy: ./bin/restore.sh [--backup ~/backup-2026-10-20] [--skip-brew]
#
# Mỗi bước idempotent, có thể chạy lại từng phần bằng --step <name>.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP="${HOME}/backup-2026-10-20"
STEP="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --backup) BACKUP="$2"; shift 2 ;;
    --step)   STEP="$2"; shift 2 ;;
    --skip-brew) SKIP_BREW=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    *) echo "unknown arg: $1"; exit 2 ;;
  esac
done

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ─────────────────────────────────────────────────────────────
step_prereq() {
  log "Kiểm tra prerequisites"
  xcode-select -p >/dev/null 2>&1 || { warn "Cài Xcode CLT: xcode-select --install"; return 1; }
  have brew || { warn "Chưa có Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; return 1; }
  eval "$(/opt/homebrew/bin/brew shellenv)"
  have git || { warn "Thiếu git"; return 1; }
  echo "OK: $(sw_vers -productVersion) $(uname -m)"
}

# ─────────────────────────────────────────────────────────────
step_brew() {
  log "Cài Homebrew bundle từ Brewfile"
  if [ "${SKIP_BREW:-0}" = "1" ]; then warn "skip theo yêu cầu"; return 0; fi
  brew bundle install --file "$REPO/Brewfile" --no-lock
  # một số tap riêng có thể lỗi — không chặn các bước sau
  brew bundle check --file "$REPO/Brewfile" || warn "Một số package chưa cài được, xem log phía trên"
}

# ─────────────────────────────────────────────────────────────
step_secrets() {
  log "Khôi phục secrets"
  local S="$BACKUP/10-secrets/bundle"
  if [ ! -d "$S" ]; then
    warn "Không thấy $S — giải mã archive trước (xem header file này)"; return 1
  fi
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  rsync -a "$S/ssh/" ~/.ssh/
  chmod 600 ~/.ssh/id_* ~/.ssh/*_rsa ~/.ssh/*.pem 2>/dev/null
  chmod 644 ~/.ssh/*.pub ~/.ssh/config ~/.ssh/known_hosts 2>/dev/null
  chmod 700 ~/.ssh
  [ -d "$S/gnupg" ] && { mkdir -p ~/.gnupg; rsync -a "$S/gnupg/" ~/.gnupg/; chmod 700 ~/.gnupg; }
  for d in .aws .kube; do [ -d "$S/etc/$d" ] && rsync -a "$S/etc/$d/" "$HOME/$d/"; done
  for f in .netrc .npmrc .pypirc; do [ -f "$S/etc/$f" ] && cp "$S/etc/$f" "$HOME/$f"; done
  [ -f "$S/etc/gh/hosts.yml" ] && { mkdir -p ~/.config/gh; cp "$S/etc/gh/hosts.yml" ~/.config/gh/; }
  [ -d "$S/etc/glab-cli" ] && { mkdir -p ~/.config/glab-cli; rsync -a "$S/etc/glab-cli/" ~/.config/glab-cli/; }
  [ -f "$S/etc/docker/config.json" ] && { mkdir -p ~/.docker; cp "$S/etc/docker/config.json" ~/.docker/; }
  [ -f "$S/kubeconfigs/tinypulse-staging.yaml" ] && cp "$S"/kubeconfigs/tinypulse-*.yaml "$HOME/" 2>/dev/null
  [ -f "$S/zsh_secrets" ] && { cp "$S/zsh_secrets" ~/.zsh_secrets; chmod 600 ~/.zsh_secrets; }
  [ -f "$S/hammerspoon-secrets.lua" ] && cp "$S/hammerspoon-secrets.lua" "$REPO/.hammerspoon/secrets.lua"
  [ -f "$S/hermes/auth.json" ] && { mkdir -p ~/.hermes; cp "$S/hermes/auth.json" ~/.hermes/; chmod 600 ~/.hermes/auth.json; }
  [ -f "$S/colima-ssh_config" ] && { mkdir -p ~/.colima; cp "$S/colima-ssh_config" ~/.colima/ssh_config; }
  # claude: khôi phục token đã sanitize (nếu muốn dùng lại gateway)
  if [ -f "$S/claude-disabled-env.txt" ] && [ -f "$REPO/.claude/settings.json" ]; then
    echo "  (claude token nằm trong $S/claude-disabled-env.txt — dán lại vào .claude/settings.json nếu cần)"
  fi
  echo "Nhớ: ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
}

# ─────────────────────────────────────────────────────────────
step_link() {
  log "Tạo symlink config"
  "$REPO/bin/link.sh"
}

# ─────────────────────────────────────────────────────────────
step_state() {
  log "Khôi phục state (claude / hermes / opencode)"
  local S="$BACKUP/20-state"
  for a in "$S"/*.tar.zst; do
    [ -f "$a" ] || continue
    echo "  -> $(basename "$a")"
    zstd -dc "$a" | tar -xf - -C "$HOME"
  done
  # config app tự ghi: copy từ repo (không symlink)
  [ -f "$REPO/.hermes/config.yaml" ] && { mkdir -p ~/.hermes; cp "$REPO/.hermes/config.yaml" ~/.hermes/; }
  [ -f "$REPO/.hermes/SOUL.md" ] && cp "$REPO/.hermes/SOUL.md" ~/.hermes/
  [ -d "$REPO/.hermes/skills" ] && { mkdir -p ~/.hermes/skills; rsync -a "$REPO/.hermes/skills/" ~/.hermes/skills/; }
  [ -f "$REPO/.claude/settings.json" ] && { mkdir -p ~/.claude; cp "$REPO/.claude/settings.json" ~/.claude/; }
  for p in CLAUDE.md statusline-command.sh agents hooks rules; do
    [ -e "$REPO/.claude/$p" ] && rsync -a "$REPO/.claude/$p" ~/.claude/
  done
  for p in opencode.json oh-my-opencode.json tui.json AGENTS.md package.json agents commands skills plugins; do
    [ -e "$REPO/.config/opencode/$p" ] && { mkdir -p ~/.config/opencode; rsync -a "$REPO/.config/opencode/$p" ~/.config/opencode/; }
  done
  warn "Nếu đã restore archive claude-state thì settings.json trong archive là bản cũ hơn — kiểm tra lại hooks."
}

# ─────────────────────────────────────────────────────────────
step_toolchains() {
  log "Cài lại toolchain theo version đã pin"

  if have asdf && [ -f "$HOME/.tool-versions" ]; then
    cut -d' ' -f1 "$HOME/.tool-versions" | sort -u | while read -r p; do
      [ -n "$p" ] || continue
      asdf plugin add "$p" 2>/dev/null || true
    done
    asdf install || warn "asdf install lỗi một phần — chạy lại sau"
  fi

  if have mise; then
    mise trust -a 2>/dev/null || true
    mise install || warn "mise install lỗi một phần"
  fi

  if have uv && [ -f "$REPO/docs/manifests/uv-tools.txt" ]; then
    awk '/^[a-z0-9_-]+ v/{print $1}' "$REPO/docs/manifests/uv-tools.txt" | while read -r t; do
      uv tool install "$t" || true
    done
  fi

  if have gem && [ -f "$REPO/docs/manifests/gem-nondefault.txt" ]; then
    while read -r g; do
      [ -n "$g" ] || continue
      gem install "$g" --no-document || true
    done < "$REPO/docs/manifests/gem-nondefault.txt"
  fi

  if have bun && [ -f "$REPO/docs/manifests/bun-global-direct.txt" ]; then
    grep -oE '@?[a-zA-Z0-9@/_-]+@[0-9][0-9.]*' "$REPO/docs/manifests/bun-global-direct.txt" | while read -r p; do
      bun add -g "$p" || true
    done
  fi
}

# ─────────────────────────────────────────────────────────────
step_services() {
  log "Bật lại brew services"
  for s in mysql@8.0 postgresql@14 redis; do
    brew services start "$s" 2>/dev/null && echo "  started $s"
  done
  sleep 3
  brew services list | head -10
}

# ─────────────────────────────────────────────────────────────
step_db() {
  log "Restore database"
  local D="$BACKUP/30-db"
  if [ -f "$D/mysql-user-dbs.sql.gz" ]; then
    echo "  mysql: import ($(du -h "$D/mysql-user-dbs.sql.gz" | cut -f1)) — có thể mất 10-20 phút"
    gunzip -c "$D/mysql-user-dbs.sql.gz" | /opt/homebrew/opt/mysql@8.0/bin/mysql -uroot
  else warn "không thấy mysql dump"; fi
  for f in "$D"/pg-*.dump; do
    [ -f "$f" ] || continue
    local db="${f##*/pg-}"; db="${db%.dump}"
    /opt/homebrew/opt/postgresql@14/bin/createdb "$db" 2>/dev/null
    /opt/homebrew/opt/postgresql@14/bin/pg_restore -d "$db" --clean --if-exists "$f" && echo "  pg: $db"
  done
  [ -f "$D/dump.rdb" ] && { redis-cli shutdown nosave 2>/dev/null; cp "$D/dump.rdb" /opt/homebrew/var/db/redis/; brew services start redis; }
  echo "  redis: 5 key trong dump.rdb (nếu có)"
}

# ─────────────────────────────────────────────────────────────
step_nvim() {
  log "Cài lại plugin Neovim (lazy.nvim + Mason)"
  have nvim || { warn "chưa có nvim"; return 0; }
  nvim --headless "+Lazy! restore" +qa 2>/dev/null || nvim --headless "+Lazy! sync" +qa 2>/dev/null
  nvim --headless "+MasonInstall lua-language-server" +qa 2>/dev/null || true
  warn "Mở nvim rồi chạy :Mason để xem server còn thiếu; :Lazy restore dùng lazy-lock.json trong repo"
}

# ─────────────────────────────────────────────────────────────
step_tmux() {
  log "Cài plugin tmux (tpm)"
  if [ -d ~/.tmux/plugins/tpm ]; then
    ~/.tmux/plugins/tpm/bin/install_plugins || true
  else
    warn "Chưa có tpm — archive tmux-plugins.tar.zst đã chứa sẵn, kiểm tra $BACKUP/20-state"
  fi
}

# ─────────────────────────────────────────────────────────────
step_hermes() {
  log "Cài Hermes Agent"
  if have hermes; then echo "  đã có: $(hermes --version 2>/dev/null | head -1)"; return 0; fi
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
  warn "Sau khi cài: chạy 'hermes' để login, rồi khôi phục profile/gateway LaunchAgents trong $BACKUP/40-apps/launchagents"
}

# ─────────────────────────────────────────────────────────────
step_claude() {
  log "Cài Claude Code CLI (native)"
  have claude && { echo "  đã có"; return 0; }
  curl -fsSL https://claude.ai/install.sh | bash
}

# ─────────────────────────────────────────────────────────────
step_manual() {
  cat <<'EOF'

── CÒN LẠI LÀM TAY ──────────────────────────────────────────────
1. App không qua brew: xem docs/manifests/applications.txt
   (Company Portal, JamfProtect, FortiClient, Azure VPN, Microsoft 365...)
2. Đăng nhập: Bitwarden, iCloud, Google, Slack/Teams, VPN, Ollama
3. VS Code: cài extension theo docs/manifests/vscode-extensions.txt
4. Font: so docs/manifests/user-fonts.txt với ~/Library/Fonts, cài phần thiếu
5. macOS defaults: xem docs/manifests/macos-defaults.txt (KHÔNG auto-apply)
6. Keychain / Wi-Fi / Touch ID / FileVault: tự nhiên theo máy mới
7. Docker: brew install colima docker && colima start (image pull lại)
8. Ollama models: ollama pull <model> (4.2G, không backup)
9. Hermes gateway LaunchAgents: cp $BACKUP/40-apps/launchagents/*.plist ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/ai.hermes.gateway-*.plist
─────────────────────────────────────────────────────────────────
EOF
}

# ─────────────────────────────────────────────────────────────
run_step() {
  if [ "${DRYRUN:-0}" = 1 ]; then
    if [ "$1" = "all" ]; then
      echo "DRY-RUN — thứ tự các bước:"
      echo "  1 prereq   2 brew   3 secrets   4 link   5 state   6 toolchains"
      echo "  7 services 8 db     9 nvim     10 tmux  11 hermes 12 claude  13 manual"
      echo "Backup dir: $BACKUP"
      echo "Repo:       $REPO"
      return 0
    fi
    echo "DRY-RUN: would run step '$1'"
    return 0
  fi
  case "$1" in
    prereq) step_prereq ;;
    brew) step_brew ;;
    secrets) step_secrets ;;
    link) step_link ;;
    state) step_state ;;
    toolchains) step_toolchains ;;
    services) step_services ;;
    db) step_db ;;
    nvim) step_nvim ;;
    tmux) step_tmux ;;
    hermes) step_hermes ;;
    claude) step_claude ;;
    all)
      step_prereq || exit 1
      step_brew
      step_secrets
      step_link
      step_state
      step_toolchains
      step_services
      step_db
      step_nvim
      step_tmux
      step_hermes
      step_claude
      step_manual
      ;;
    *) echo "step không hợp lệ: $1"; exit 2 ;;
  esac
}
run_step "$STEP"

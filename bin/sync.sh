#!/usr/bin/env bash
# sync.sh — chụp lại config do app tự ghi từ $HOME vào repo (snapshot).
# Chạy trước khi backup / trước khi reset máy.
#
# Nguyên tắc:
#   - config tĩnh (zsh, tmux, git, nvim, alacritty, kitty, hammerspoon) -> symlink, không copy
#   - config app tự ghi -> copy snapshot, KHÔNG symlink (app ghi đè bằng rename sẽ phá symlink)
#   - secrets -> không bao giờ copy vào repo
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="${HOME}"

echo "== opencode =="
mkdir -p "$REPO/.config/opencode"
rsync -a \
  --exclude node_modules --exclude '.omo' --exclude 'bun.lock' --exclude 'package-lock.json' \
  --exclude '*backup-*' --exclude '*pre-reconfig*' --exclude '*.bak' --exclude '*.claude-only-*' \
  --exclude '.caveman-active' --exclude '.ponytail-active' \
  "$H/.config/opencode/" "$REPO/.config/opencode/"

echo "== claude (config only) =="
mkdir -p "$REPO/.claude"
for p in settings.json CLAUDE.md statusline-command.sh agents hooks rules; do
  [ -e "$H/.claude/$p" ] || continue
  rsync -a "$H/.claude/$p" "$REPO/.claude/"
done
# sanitize token trong settings.json
python3 - "$REPO/.claude/settings.json" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p)); env=d.get('env',{}); changed=[]
for k in ('_DISABLED_ANTHROPIC_AUTH_TOKEN','_DISABLED_OTEL_EXPORTER_OTLP_HEADERS'):
    if env.get(k) and env[k] != 'REPLACE_ME' and 'REPLACE_ME' not in str(env[k]):
        env[k]='REPLACE_ME' if k.endswith('TOKEN') else 'Authorization=REPLACE_ME'; changed.append(k)
if changed:
    json.dump(d, open(p,'w'), indent=2)
    print('  sanitized:', ', '.join(changed))
PY

echo "== hermes (config only) =="
mkdir -p "$REPO/.hermes"
for p in config.yaml SOUL.md skills; do
  [ -e "$H/.hermes/$p" ] || continue
  rsync -a "$H/.hermes/$p" "$REPO/.hermes/"
done

echo "== xong =="
echo "Kiểm tra: git -C $REPO status --short"

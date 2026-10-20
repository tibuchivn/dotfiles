#!/bin/bash
# PATH report for macOS/zsh: clean login+interactive baseline, duplicate attribution,
# suspicious-entry scan, and every PATH-mutating line in the startup files.
# Usage: bash path-report.sh [shell-binary]   (default /bin/zsh)
set -u

SHELL_BIN="${1:-/bin/zsh}"
STARTUP="/etc/zshenv /etc/zprofile /etc/zshrc /etc/zlogin $HOME/.zshenv $HOME/.zprofile $HOME/.zshrc $HOME/.zlogin $HOME/.profile $HOME/.config/fish/config.fish $HOME/.bashrc $HOME/.bash_profile"

FRESH=$(env -i HOME="$HOME" USER="${USER:-$(id -un)}" TERM=xterm-256color SHELL="$SHELL_BIN" \
  "$SHELL_BIN" -l -i -c 'echo "$PATH"' 2>/dev/null | tail -1)

if [ -z "$FRESH" ]; then
  echo "could not read a PATH from $SHELL_BIN -l -i" >&2
  exit 1
fi

echo "== real shell PATH ($(printf '%s' "$FRESH" | tr ':' '\n' | wc -l | tr -d ' ') entries) =="
printf '%s' "$FRESH" | tr ':' '\n' | nl

echo
echo "== duplicates (in the user's shell, not the agent's) =="
DUPS=$(printf '%s' "$FRESH" | tr ':' '\n' | sort | uniq -d)
if [ -z "$DUPS" ]; then
  echo "(none)"
else
  printf '%s\n' "$DUPS" | while IFS= read -r d; do
    [ -n "$d" ] || continue
    n=$(printf '%s' "$FRESH" | tr ':' '\n' | grep -cxF -- "$d")
    echo "-- x$n  $d"
    for f in $STARTUP; do
      [ -f "$f" ] || continue
      grep -nF -- "$d" "$f" 2>/dev/null | sed "s|^|     $f:|"
    done
  done
fi

echo
echo "== suspicious entries =="
printf '%s' "$FRESH" | tr ':' '\n' | grep -vE '^(/|~)' | sed 's/^/  relative: /'
printf '%s' "$FRESH" | tr ':' '\n' | grep -E '^~' | sed 's/^/  unexpanded tilde: /'
printf '%s' "$FRESH" | tr ':' '\n' | grep -E '/$' | sed 's/^/  trailing slash: /'

echo
echo "== PATH-mutating lines in startup files =="
for f in $STARTUP; do
  [ -f "$f" ] || continue
  out=$(grep -nE '(^|[^A-Za-z_])PATH=|path_helper|shellenv|fish_add_path|Added by' "$f" 2>/dev/null)
  [ -n "$out" ] && { echo "-- $f"; printf '%s\n' "$out"; }
done

echo
echo "== /etc/paths.d (appended by path_helper; '~' is NOT expanded) =="
for f in /etc/paths.d/*; do
  [ -f "$f" ] || continue
  printf '%s: ' "$(basename "$f")"
  tr '\n' ' ' < "$f"
  echo
done

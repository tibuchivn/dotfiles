---
name: shell-path-diagnosis
description: Use when which shows the wrong binary or PATH repeats.
version: 0.1.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [shell, path, zsh, dotfiles, shims, macos]
    related_skills: [nvim-config-profiles, systematic-debugging]
---

# Shell PATH diagnosis and cleanup (macOS / zsh)

Two question types, same procedure: "why does `which X` return that?" and "where are my PATH duplicates coming from?".

## When to Use

- `which` / `command -v` returns a path the user did not install, or a path under a dot-directory they do not recognise.
- The same directory appears more than once in `$PATH`, or a command behaves differently in a new shell than in the current one.
- A tool installed itself into the shell (a wrapper/shim, an installer block appended to `.zshrc`/`.bashrc`/fish config) and the user wants to know what it is or undo it.
- Don't use for: a command that is simply not installed (fix the install, not PATH); Python/Node package resolution inside a venv.


## Measure the user's real shell, never the agent's own $PATH

The persistent terminal session carries Hermes tool dirs and accumulates one prepended copy per rc re-source, so its `$PATH` shows phantom duplicates and hides entries. Diagnosing from it produces wrong attributions. Take a clean baseline instead:

    env -i HOME="$HOME" USER="$USER" TERM=xterm-256color SHELL=/bin/zsh \
      /bin/zsh -l -i -c 'echo "$PATH"'

`env -i` stops inherited PATH from masking rc behaviour; `-l` reads `.zprofile`, `-i` reads `.zshrc` (without `-i` you miss almost every user prepend). Ignore `can't change option: zle` noise. Save the output to a file — every later diff needs it.

Then separate the two worlds explicitly when reporting: duplicates present in the fresh shell are the user's config; extras only in the agent's shell are session artifacts and must not be "fixed". A multiset diff (`Counter` on the two lists) is the honest way to split them.

`scripts/path-report.sh` runs the clean baseline, lists duplicates, greps every startup file for each duplicate, and flags relative / unexpanded-`~` entries. Run it before hand-typing any of this.

## Step 1 — what is actually resolving

    which -a git; type -a git

Order matters: first hit wins, and a prepend at the *end* of `.zshrc` beats everything path_helper added earlier. Note repeats in different positions — they reveal how many times the config was sourced.

A wrapper can be indistinguishable from the real binary by behaviour: `git --version` printing the real version proves nothing because the shim delegates. Trust `which`, not version output.

## Step 2 — identify the binary before calling it suspicious

    ls -la <dir>/                 # symlink chain, e.g. git -> wrapper, git-og -> real git
    file <binary>                 # Mach-O thin arm64, script, etc.
    codesign -dv --verbose=2 <binary>
    strings -a <binary> | grep -iE 'https?://|install\.sh|@see' | sort -u | head
    ps aux | grep -i <name> | grep -v grep

The directory name is often a rebrand: `strings` yields the canonical install URL and project name (this is how a shim named after the directory turned out to be Git AI / usegitai.com). Also read a sidecar `config.json` in that directory, and check whether it edited global tool config:

    git config --global --list --show-origin | grep -iE 'trace2|hooks|ai'

Report what the tool *is and does* (here: records AI-vs-human authorship into `refs/notes/ai` via a background daemon and a `trace2.eventtarget` socket) with the evidence inline, then state plainly it is not malware if the evidence says so. Do not delete an installation the user has not asked to remove.

## Step 3 — attribute every entry to a source line

Grep the whole startup set for PATH mutation, and separately for the tool that is being blamed:

    for f in /etc/zshenv /etc/zprofile /etc/zshrc /etc/zlogin \
             ~/.zshenv ~/.zprofile ~/.zshrc ~/.zlogin ~/.profile \
             ~/.config/fish/config.fish ~/.config/fish/conf.d/*.fish; do
      [ -f "$f" ] || continue
      grep -nE 'PATH=|path_helper|shellenv|fish_add_path|source |\. "' "$f"
    done

Also grep for installer markers — `grep -rn "<dir-name>" ~/.zshrc ~/.zprofile ~/.bashrc ~/.config/fish` — multi-line blocks commented `# Added by <product> installer` are the fastest provenance, and their duplication shows the installer ran more than once.

System-level contributors on macOS: `/etc/zprofile` calls `/usr/libexec/path_helper`, which appends `/etc/paths` and `/etc/paths.d/*`. Duplicates between those and `~/.zshrc` lines are common. LaunchAgents/Daemons (`~/Library/LaunchAgents`, `/Library/LaunchAgents`, `/Library/LaunchDaemons`) can inject PATH too — grep them for the tool name.

Read `references/macos-zsh-path-sources.md` for the startup order, which file multiplies fastest, and the non-obvious path_helper quirks.

## Step 4 — report before editing

Give one line per duplicate group: the entries, then `file:line` of every source with the actual `export` line quoted. Call out broken entries separately (they are not duplicates but still wrong). End with the concrete edit plan and the expected entry count after. Then ask.

The user often wants some of what looks like cruft (a git wrapper installed deliberately). Never bundle unrelated removals into "cleanup"; propose, wait for confirmation, and keep the count honest (`43 -> 36 entries, no duplicates left`).

## Step 5 — edit, back up, verify

1. Back up every rc file first, kept together so one `cp` restores the whole state:

       mkdir -p ~/.hermes/cache/scratch/pathbackup-$(date +%Y%m%d-%H%M%S)
       cp ~/.zshrc ~/.zprofile ~/.zshenv <that dir>/

   Verify the backup actually holds the dotfiles — `ls -l` without `-a` shows `total 0` for a directory of dotfiles and looks like a failed copy.
2. Remove one line per duplicate; keep exactly one occurrence, chosen by reach: `~/.zshenv` applies to every zsh including non-interactive and subprocess shells, `.zprofile` to login shells, `.zshrc` to interactive ones. Delete a whole installer block (comment + export) so a re-run of the installer's grep finds nothing stale.
3. Syntax check: `zsh -n ~/.zshrc && zsh -n ~/.zprofile`.
4. Re-measure the fresh shell: entry count fell by exactly the number of removed lines, `tr ':' '\n' | sort | uniq -d` prints nothing, and a Counter diff shows no directory that dropped to zero occurrences — that check is what proves no unique dir was collateral damage.
5. Resolution sweep in that same fresh shell — `command -v` over the tools the user relies on (git, brew, node, python3, go, cargo, asdf/pyenv, gh, mysql, and the wrapped binary) plus a functional call (`git --version`) for anything that runs a daemon.

## Pitfalls

- A prepend typo missing the leading slash (`export PATH=/bin:/usr/local/bin:usr/bin:$PATH`) silently adds a cwd-relative `usr/bin` and duplicates `/bin` and `/usr/local/bin`. Delete the whole line rather than "fixing" it when `path_helper` already supplies those dirs.
- `/etc/paths.d/*` entries are appended verbatim — `~/.dotnet/tools` stays literal and never resolves. Fixing that file needs sudo, so report it and leave it alone unless asked.
- `.local/bin/env`-style installers are self-guarding (`case ":$PATH:"` check), so sourcing them adds nothing; don't count them as a duplicate source or "fix" them.
- `~/.zshrc` on this machine is a live file, not a symlink into the dotfiles repo, so rc edits diverge from the tracked copy. Say so when you edit, and offer to port the change to `~/tung/dotfiles`.
- Editing only `.zshrc` leaves login-shell tools (Homebrew `shellenv`, solana, etc. in `.zprofile`) duplicated on every login. Enumerate duplicates from the fresh *login+interactive* baseline so both files are in view.
- Report in the language the user writes in (they use Vietnamese), and keep the numbered command block copy-pasteable instead of prose.

## Supporting files

- `references/macos-zsh-path-sources.md` — zsh startup order, what path_helper does, where each class of prepend usually comes from.
- `scripts/path-report.sh` — clean baseline + duplicate attribution + suspicious-entry scan.

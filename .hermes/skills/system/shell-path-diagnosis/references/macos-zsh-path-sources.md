# macOS zsh PATH sources — order and behaviour

## Startup order for `zsh -l -i`

| # | File | Read for | Effect on PATH |
|---|------|----------|----------------|
| 1 | `/etc/zshenv` | every zsh | yes |
| 2 | `~/.zshenv` | every zsh, incl. non-interactive and every subprocess zsh | yes — **multiplies fastest** |
| 3 | `/etc/zprofile` | login | runs `path_helper` |
| 4 | `~/.zprofile` | login | yes (Homebrew `shellenv`, toolchains) |
| 5 | `/etc/zshrc` | interactive | yes (sources `/etc/zshrc_$TERM_PROGRAM`) |
| 6 | `~/.zshrc` | interactive | yes (bulk of user prepends) |
| 7 | `~/.zlogin` | login | yes |

Later prepends land in front, so a line near the bottom of `~/.zshrc` wins over everything path_helper added at step 3. `~/.zshenv` is read again by every zsh the user or a script spawns, which is why a single prepend there shows up several times in a nested-shell PATH.

Non-interactive `zsh -c` reads only steps 1–2 (plus `~/.zprofile`/`~/.zlogin` when invoked as a login shell). A prepend that lives only in `~/.zshrc` therefore disappears for scripts, editors, and cron — choose the file by intended reach, not by convenience.

## path_helper

`/etc/zprofile` runs:

    eval `/usr/libexec/path_helper -s`

which rebuilds PATH from `/etc/paths` plus every `/etc/paths.d/*` file, appended after what zshenv/zprofile already set. On a stock machine `/etc/paths` is:

    /usr/local/bin
    /System/Cryptexes/App/usr/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin

Consequences:

- Any `export PATH=/usr/local/bin:...` in `~/.zshrc` duplicates what path_helper already provides. Those lines are usually ancient macOS-vs-Linux muscle memory and can go.
- `/etc/paths.d/*` is appended verbatim: a `~` inside one of those files is **not** expanded, so `~/.dotnet/tools` sits in PATH as a literal and never resolves. Editing it needs sudo.
- path_helper does not dedupe against entries added later by `~/.zshrc`.

## Usual sources of each duplicate

- `~/.local/bin` — `~/.zshenv` + `~/.zprofile` + `~/.zshrc`, each from a different installer (CLI installers, pipx, `uv`); plus a guarded `~/.local/bin/env` that adds nothing.
- Shared bin dir — installer blocks appended twice: `# Added by <product> installer` appearing twice in `~/.zshrc` means the installer ran more than once; the block is always comment + `export`.
- Toolchain bin (solana, mysql@8.0, python@x, qt) — present in both `~/.zprofile` and a later `~/.zshrc` section, because the section was pasted twice at different times.
- Homebrew — `eval "$(brew shellenv)"` in `~/.zprofile` and, separately, opts dirs prepended per formula in `~/.zshrc`. Not duplicates; leave them.
- PATH shims/wrappers (`git`, `node`, `python`) — first entry, owned by a tracking or version-manager tool. Identify by symlink target plus `strings`; keep if intentional.

## Sanity checks after cleanup

    env -i HOME="$HOME" USER="$USER" TERM=xterm-256color SHELL=/bin/zsh \
      /bin/zsh -l -i -c 'echo $PATH' | tr ':' '\n' | sort | uniq -d    # expect empty

    env -i ... /bin/zsh -l -i -c 'for c in git brew node python3 go gh; do
        printf "%-10s %s\n" "$c" "$(command -v $c || echo MISSING)"; done'

A `MISSING` for a tool whose framework directory does not exist (a stale `/etc/paths.d` entry) is pre-existing breakage, not something the PATH edit caused — check the directory before reporting it as a regression.

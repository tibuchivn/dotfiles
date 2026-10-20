---
name: nvim-config-profiles
description: Use when creating or changing an NVIM_APPNAME nvim profile.
---

# Neovim config profiles (NVIM_APPNAME)

`NVIM_APPNAME=<name> nvim` relocates four paths — consider all of them:

    ~/.config/<name>          config (symlink into dotfiles repo)
    ~/.local/share/<name>     plugin dirs, lazy.nvim
    ~/.local/state/<name>     shada, sessions
    ~/.cache/<name>           cache

Convention here: real files live in `~/tung/dotfiles/.config/<name>`, and `~/.config/<name>` is a symlink to it, mirroring how `~/.config/nvim -> ~/tung/dotfiles/.config/nvim` is wired.

## Cloning an existing profile

    cd ~/tung/dotfiles/.config
    rsync -a --exclude '.DS_Store' --exclude '.sisyphus' nvim/ <name>/
    ln -sfn ~/tung/dotfiles/.config/<name> ~/.config/<name>

`.sisyphus/` is agent scratch and must never be copied; `.gitignore` already covers it.

## Removing a plugin cleanly

Grep the whole profile for the plugin name before editing — lazy specs are spread over `lua/plugins/*.lua`, and dead references hide in commented lines:

    search_files(pattern='<plugin>', path=~/tung/dotfiles/.config/<name>)

Remove every one of: the spec entry / `dependencies` block, its init config (e.g. `vim.g.<plugin>_settings`), any `local x = require '<plugin>'`, commented references, and the entry in `lazy-lock.json` (lazy prunes stale lock entries on sync, but pruning by hand keeps the diff readable). Backup files like `old_init.vim.bk` are historical and safe to leave.

## Installing plugins for a profile

    cd ~ && NVIM_APPNAME=<name> nvim --headless "+Lazy! sync" +qa

First run also bootstraps lazy.nvim into `~/.local/share/<name>/lazy/lazy.nvim`. Cloning ~50 plugins can exceed the foreground timeout — run it with `background=true, notify=true` and wait on the process.

## Verification (do this, don't assume)

1. Plain load check:

       NVIM_APPNAME=<name> nvim --headless -c 'lua print(vim.tbl_contains(vim.opt.rtp:get(), vim.fn.stdpath("data").."/lazy/<removed-plugin>"))' -c 'qa!'

2. Real-UI check in tmux on a private socket (`tmux -L <sock>`) so the user's sessions stay untouched. `capture-pane` alone is unreliable for the completion popup — instead log `CompleteChanged` events to a file from inside nvim:

       vim.api.nvim_create_autocmd("CompleteChanged", { callback = function()
         local items = vim.fn.complete_info({ "items" }).items
         -- append words + timestamp to a file
       end })

   Launch with `NVIM_APPNAME=<name> nvim file -c 'luafile cc.lua'`, `send-keys` Escape/G/o/<literal text>/`C-x C-u`, then read the log. Two events (fuzzy, then re-ranked) prove the pipeline.

3. Upstream unit tests run without the profile: `nvim --headless -u NONE --cmd "set rtp^=$(pwd)" -c "luafile tests/test_phase3.lua" -c "qa!"`.

## Verifying a completion plugin in a real UI

- nvim-cmp only auto-triggers when the cursor advanced exactly one column since the previous `TextChangedI` (`lp` guard in `lua/cmp/init.lua`). A `tmux send-keys -l "config"` burst produces a single event that the guard discards, so type character by character with a ~0.35s sleep between keys; otherwise you will wrongly conclude the plugin is broken.
- cmp's default (custom, floating-window) entries view never fires `CompleteChanged`, so the CompleteChanged logger shows nothing even when the menu is open. For cmp, scrape the popup with `tmux capture-pane` instead: the candidate column shows the LSP kind (`Function`, `Variable`, ...) for LSP items and `Text` for cmp-buffer items.
- To prove the `nvim_lsp` source without a working language server, run a ~40-line fake LSP over stdio (Python: `Content-Length` framed JSON-RPC, answer `initialize` with a `completionProvider` capability and `textDocument/completion` with one item), start it with `vim.lsp.start({ name = ..., cmd = {...}, root_dir = ... })`, and check the item shows up in the menu. This exercises the capabilities handshake and the source wiring for real.
- Language servers that go through asdf shims (`typescript-language-server`) exit 126 / fail `initialize` outside a project with a matching `.tool-versions`; that is an environment problem, not a config bug.

## Writing a custom completion source (example: ctags)

Before hand-rolling a source, check whether one exists (`gh search repos '<topic>'`, e.g. `cmp-tags`): nvim-cmp bundles **zero** sources — even `buffer` is the separate cmp-buffer plugin, which self-registers from `after/plugin/cmp_buffer.lua` — so every capability is either a plugin or custom code, and there is no config knob for things like tags. Known plugin for this case: `quangnguyen30192/cmp-nvim-tags` (`{ name = "tags", option = { complete_defer, max_items, keyword_length, exact_match, current_buffer_only } }`; it also uses `taglist()` and documents a `vim.lsp.tagfunc` / `workspace/symbol` pitfall to clear on attach). Zero-code fallback: the builtin `i_CTRL-X_CTRL-]` tags completion keeps working while cmp owns the menu — verified in a real UI. (it honours the `tags` option, so `./tags;` upward search and gutentags-generated project tags both work, and it returns `[]`, not an error, when there is no tags file).

- Register with `cmp.register_source("tags", require("my_tags.source").new())` from the plugin's `config`, and list it in `sources`; a per-source `keyword_length` in that table arrives as `params.option`.
- cmp renders the menu kind as `types.lsp.CompletionItemKind[item.kind]`. A string kind (e.g. ctags' `"f"`) is not in the reverse enum, so it silently renders as `Text` — always map kind letters to the numeric enum (fallback `Reference`, which keeps ctags entries distinguishable from cmp-buffer's `Text`).
- Set `label`, `word` and `insertText` on each item; `detail` and `documentation = { kind = "plaintext", value = ... }` render without needing `source.resolve`.
- `source.is_available` is called on every request: cache the probe (~2s).
- `taglist()` is a linear scan of the tag *names*: 1.5 ms on a ~3k-entry tags file, ~18 ms on 200k entries / 11 MB. Cache the taglist output per prefix for ~2s (cmp re-requests the same prefix on redraws) and truncate it; build the item tables fresh so cmp never receives shared tables.

## AI completion sources (minuet-ai.nvim + nvim-cmp)

- `minuet-ai.nvim` registers its cmp source inside `setup()` (`require('cmp').register_source('minuet', ...)`, only when `require('cmp')` works), so the plugin must load eagerly (`lazy = false`) and its spec must be ordered/written so cmp's module is on the rtp by then. Add `{ name = 'minuet' }` to cmp sources and raise `performance.fetching_timeout` (cmp defaults to 500ms; LLM calls take 0.6-1s), plus `mapping['<A-y>'] = require('minuet').make_cmp_map()` for on-demand use.
- `provider_options.<provider>.api_key` is the **name of an environment variable** (looked up as `vim.env[name]`); a `function()` returning the string also works (`minuet.utils.get_api_key`). Pick the function form when the key must come from a file instead of the environment.
- Minuet's cmp source uses trigger characters (`{ '@', '.', '(', '[', ':', ' ' }`) and a deliberately non-matching `keyword_pattern` of `^$`, so it never filters on the typed word — expect its entries to appear only after a trigger character (or `<A-y>`), not on every keystroke.
- nvim-cmp configures keys with its own listener, so its mappings never show up in `:imap` / `maparg` (a `MISSING` result there is a false alarm) — inspect `require('cmp').get_config().mapping` instead, where `<A-y>` is normalized to `<M-y>`. Any Alt/Option mapping also needs the terminal to send Option as Meta: Alacritty `[window] option_as_alt = "Both"`, kitty `macos_option_as_alt yes`, Ghostty `macos-option-as-alt`. Confirm the change without restarting via `alacritty msg get-config` (check `window.option_as_alt`); it is live when `general.live_config_reload` is true.
- DeepSeek FIM: provider `openai_fim_compatible`, `end_point = 'https://api.deepseek.com/beta/completions'`, model id from `GET /models` (`deepseek-flash`). Verify a key/model without ever printing the key: `curl https://api.deepseek.com/models -H "Authorization: Bearer $KEY"`, then POST a tiny prompt to `/beta/completions`.
- Verifying an API-backed source: drive the backend directly in headless nvim (`require('minuet.backends.openai_fim_compatible').complete({ lines_before, lines_after, opts }, cb)` + `vim.wait`) — faster and more deterministic than the UI; then confirm the UI path in tmux.
- Headless `print()` output is lost if the process is killed, and an error inside a `-c luafile` script leaves headless nvim hanging (SIGTERM at timeout): write results to a file with `vim.fn.writefile` as you go so a hang cannot swallow the evidence.
- Never let a key reach the terminal: inject it into a tmux pane with a `0600` env file that the launched shell sources, or `tmux set-environment` before the pane is created (setting it after the pane exists has no effect on that pane). Capturing the pane would otherwise show the key in the echoed command line.

## Pitfalls

- Headless nvim never enters insert mode via `startinsert` + `feedkeys`, so `complete_info()` is always empty there: a completion popup can only be verified in a real UI (tmux).
- Tests that assert "no API key present" fail when the key is exported in the shell — check whether a failure is environmental before reporting it as breakage.
- `NVIM_APPNAME` is read at startup only; exporting it mid-session does nothing.
- Anything using `stdpath("data")` (lazy plugin paths, e.g. copilot-language-server.js) resolves per profile, so each profile gets its own copy of plugin binaries.

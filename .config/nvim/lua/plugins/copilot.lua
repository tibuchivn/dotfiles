return {
  {
    'github/copilot.vim',
    event = "VeryLazy",
    init = function()
      -- macOS: use pinned Homebrew node@22 if present; else fall back to PATH `node` (Windows/Linux)
      local brew_node = '/opt/homebrew/opt/node@22/bin/node'
      if vim.fn.executable(brew_node) == 1 then
        vim.g.copilot_node_command = brew_node
      end
      vim.keymap.set('i', '<C-g>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
      vim.g.copilot_no_tab_map = true
      vim.keymap.set('i', '<C-L>', '<Plug>(copilot-next)')
    end,
  },
}

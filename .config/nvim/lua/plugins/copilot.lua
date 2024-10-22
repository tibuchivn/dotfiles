return {
  {
    'github/copilot.vim',
    event = "VeryLazy",
    init = function()
      vim.g.copilot_node_command = '/opt/homebrew/Cellar/node/22.8.0/bin/node'
      vim.keymap.set('i', '<C-g>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
      vim.g.copilot_no_tab_map = true
      vim.keymap.set('i', '<C-L>', '<Plug>(copilot-next)')
    end,
  },
}

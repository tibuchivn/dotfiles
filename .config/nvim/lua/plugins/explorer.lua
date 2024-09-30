return {
  {
    "echasnovski/mini.files",
    version = '*',
    config = function()
      require('mini.files').setup({
        mappings = {
          synchronize = "w",
          go_in_plus="<CR>"
        },
        windows = {
          preview = true,
          width_preview = 75,
        },
      })
      vim.keymap.set("n", "<leader>e", ":lua MiniFiles.open()<CR>")
      vim.keymap.set("n", "<leader>E", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0), true)<CR>")

      local map_split = function(buf_id, lhs, direction)
        local rhs = function()
          -- Make new window and set it as target
          local new_target_window
          vim.api.nvim_win_call(MiniFiles.get_target_window(), function()
            vim.cmd(direction .. ' split')
            new_target_window = vim.api.nvim_get_current_win()
          end)

          MiniFiles.set_target_window(new_target_window)
        end

        -- Adding `desc` will result into `show_help` entries
        local desc = 'Split ' .. direction
        vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
      end

      local show_dotfiles = true

      local filter_show = function(fs_entry)
        return true
      end

      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        require("mini.files").refresh { content = { filter = new_filter } }
      end

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = "Toogle dotfiles" })
          map_split(buf_id, 'gs', 'belowright horizontal')
          map_split(buf_id, 'gv', 'belowright vertical')
        end,
      })
    end
  },
}

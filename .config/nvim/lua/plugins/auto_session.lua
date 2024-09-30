return {
	'rmagatti/auto-session',
	config = function()
		local auto_session = require('auto-session')

		auto_session.setup({
			auto_restore_enabled = false,
		})

		local keymap = vim.keymap

		keymap.set('n', "<leader>sl", ":SessionRestore<CR>", { desc = 'Restore session for cwd' })
		keymap.set('n', "<leader>ss", ":SessionSave<CR>", { desc = 'Save Session' })
	end,
}

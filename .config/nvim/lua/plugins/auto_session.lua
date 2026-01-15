return {
	'rmagatti/auto-session',
	config = function()
		local auto_session = require('auto-session')

		auto_session.setup({
			auto_restore_enabled = false,
		})

		local keymap = vim.keymap

		keymap.set('n', "<leader>sl", ":AutoSession restore<CR>", { desc = 'Restore session for cwd' })
		keymap.set('n', "<leader>ss", ":AutoSession save<CR>", { desc = 'Save Session' })
	end,
}

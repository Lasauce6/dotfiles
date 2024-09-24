-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
		lazypath,
	}
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
	spec = {
		{ import = "plugins" },
	},
})

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- document existing key chains
require('which-key').add {
	{ "<leader>c", group = "[C]ode" },
	{ "<leader>c_", hidden = true },
	{ "<leader>d", group = "[D]ocument" },
	{ "<leader>d_", hidden = true },
	{ "<leader>g", group = "[G]it" },
	{ "<leader>g_", hidden = true },
	{ "<leader>r", group = "[R]ename" },
	{ "<leader>r_", hidden = true },
	{ "<leader>s", group = "[S]earch" },
	{ "<leader>s_", hidden = true },
	{ "<leader>w", group = "[W]orkspace" },
	{ "<leader>w_", hidden = true },
}

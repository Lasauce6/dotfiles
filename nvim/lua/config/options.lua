local opt = vim.opt

-- Disable --Insert-- line under status bar
opt.cmdheight = 0

-- Set tabs/indent
opt.tabstop = 4
opt.shiftwidth = 4
opt.syntax = "on"
opt.autoindent = true

-- Show line numbers
opt.number = true

-- Enable mouse mode
opt.mouse = 'a'
-- Sync clipboard between OS and Neovim.
opt.clipboard = 'unnamedplus'

-- Menu for completion
opt.completeopt = "menu,menuone,noselect"

-- Highlight currrent cursor line
opt.cursorline = true

-- Enable break indent
opt.breakindent = true
-- Highlight of the search
opt.hlsearch = false
-- Save undo history
opt.undofile = true
-- Case-insensitive searching UNLESS \C or capital in search
opt.ignorecase = true
opt.smartcase = true

opt.iskeyword:append("-") -- consider string-string as whole word

-- Keep signcolumn on by default
opt.signcolumn = 'yes'

-- Decrease update time
opt.updatetime = 250
opt.timeoutlen = 300

opt.termguicolors = true

-- [[ Basic Keymaps ]]
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Highlight on yank ]]
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = '*',
})

-- Show spaces/tabs/eol
opt.list = true
vim.api.nvim_command([[set listchars=tab:\|\ ,trail:·]])
vim.api.nvim_command([[set lcs+=space:·]])
opt.listchars:append('eol:↴')
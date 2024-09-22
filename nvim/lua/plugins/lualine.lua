return
{
	-- Set lualine as statusline
	'nvim-lualine/lualine.nvim',
	opts = {
		options = {
			icons_enabled = false,
			theme = 'ayu_dark',
			component_separators = '|',
			section_separators = '',
		},
	},
}

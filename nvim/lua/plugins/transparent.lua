return
{
	'xiyaowong/transparent.nvim',
	config = (function()
		require('transparent').setup({
			groups = {
				'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
				'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
				'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
				'SignColumn', 'CursorLineNr', 'EndOfBuffer', 'Pmenu', 'PmenuSel',        },
				extra_groups = {
					'GitSignsAdd', 'GitSignsChange', 'GitSignsDelete',
					'TelescopeBorder', 'TelescopePromptBorder', 'TelescopeResultsBorder',
					'TelescopePreviewBorder', 'NvimTreeNormal', 'NvimTreeEndOfBuffer',
					'NvimTreeVertSplit', 'NvimTreeStatusLine', 'NvimTreeStatusLineNC',
					'NvimTreeWindowPicker', 'NvimTreeIndentMarker', 'NvimTreeImageFile',
					'NvimTreeSymlink', 'NvimTreeFolderIcon', 'NvimTreeFolderName',
					'NvimTreeEmptyFolderName', 'NvimTreeOpenedFolderName'
				},
			})
		end
	),
}

return
{
	"hardyrafael17/norminette42.nvim",
	config = function()
		local norminette = require("norminette")

		local is_active = true

		local function toggle_norminette()
			is_active = not is_active
			norminette.setup({
				runOnSave = true,
				maxErrorsToShow = 5,
				active = is_active,
			})
			vim.notify("Norminette is now " .. (is_active and "active" or "inactive"))
		end

		norminette.setup({
			runOnSave = true,
			maxErrorsToShow = 5,
			active = is_active,
		})

		vim.keymap.set('n', '<leader>n', toggle_norminette, { desc = 'Toggle Norminette' })
	end,
}



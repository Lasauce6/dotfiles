ToggleTerm = function()
	vim.cmd(":Telescope toggleterm_manager");
end

vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], { desc = "Exit terminal mode" })
vim.keymap.set("n", "t", ToggleTerm, { desc = "Toggle Terminal Manager" })

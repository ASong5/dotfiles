return {
	"ASong5/floatingtodo.nvim",
	config = function()
		require("floatingtodo").setup({
			target_file = "~/notes/todo.md",
			border = "single", -- single, rounded, etc.
			width = 0.35, -- width of window in % of screen size
			height = 0.8, -- height of window in % of screen size
			position = "center", -- topleft, topright, bottomleft, bottomright
		})
	end,
	vim.keymap.set("n", "<leader>td", ":Td<CR>", {}),
}

return {
	{
		"nvim-mini/mini.icons",
		version = false,
		config = function()
			require("mini.icons").setup({
				style = "glyph",
			})
		end,
	},
	{
		"nvim-mini/mini.files",
		version = false,
		config = function()
			require("mini.files").setup({
				mappings = {
					close = "x",
					go_in = "<Right>",
					go_out = "<Left>",
					go_in_plus = "<Right>",
					go_out_plus = "<S-Left>",
					mark_goto = ";",
					mark_set = "m",
					synchronize = "<leader>ww",
				},
				windows = {
					preview = true,
					width_preview = vim.o.columns,
				},
			})
			vim.keymap.set("n", "<leader>rw", function()
				require("mini.files").open(vim.fn.expand("%:p"))
			end, { noremap = true, silent = true })
		end,
	},
}

return {
	"kylechui/nvim-surround",
	version = "*", -- Use for stability; omit to use `main` branch for the latest features
	event = "VeryLazy",
	config = function()
		require("nvim-surround").setup({
			-- Configuration here, or leave empty to use defaults
			keymaps = {
				normal = "<leader>ys",
				normal_cur = "<leader>yss",
				normal_line = "<leader>yS",
				normal_cur_line = "<leader>ySS",
				visual = "<leader>S",
				visual_line = "<leader>gS",
				delete = "<leader>ds",
				change = "<leader>cs",
				change_line = "<leader>cS",
			},
		})
	end,
}

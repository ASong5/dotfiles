return {
    "christoomey/vim-tmux-navigator",
    cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
        "TmuxNavigatePrevious",
    },
    lazy = false,
    setup = function()
        vim.g.tmux_navigator_no_mappings = 1
        vim.g.tmux_navigator_no_wrap = 1
        vim.g.tmux_navigator_disable_when_zoomed = 1
    end,
    keys = function()
        if os.getenv("TMUX") then
            return {
                { "<C-Left>",  "<cmd>TmuxNavigateLeft<CR>",     silent = true },
                { "<C-Down>",  "<cmd>TmuxNavigateDown<CR>",     silent = true },
                { "<C-Up>",    "<cmd>TmuxNavigateUp<CR>",       silent = true },
                { "<C-Right>", "<cmd>TmuxNavigateRight<CR>",    silent = true },
                { "<C-\\>",    "<cmd>TmuxNavigatePrevious<CR>", silent = true },
            }
        else
            return {
                { "<C-Left>",  "<C-w>h", silent = true },
                { "<C-Down>",  "<C-w>j", silent = true },
                { "<C-Up>",    "<C-w>k", silent = true },
                { "<C-Right>", "<C-w>l", silent = true },
            }
        end
    end,
}

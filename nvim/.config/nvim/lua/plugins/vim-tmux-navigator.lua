
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
    end,
    keys = {
        { "<c-Left>", "<cmd><C-U>TmuxNavigateLeft<cr>", silent = true },
        { "<c-Down>", "<cmd><C-U>TmuxNavigateDown<cr>", silent = true },
        { "<c-Up>", "<cmd><C-U>TmuxNavigateUp<cr>", silent = true },
        { "<c-Right>", "<cmd><C-U>TmuxNavigateRight<cr>", silent = true },
        { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", silent = true },
    },
}


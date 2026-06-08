return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")
        configs.setup({
            ensure_installed = {
                "lua",
                "javascript",
                "typescript",
                "c",
                "cpp",
                "html",
                "css",
                "json",
                "vimdoc",
                "svelte",
                "java",
                "kdl",
                "markdown",
                "rust",
                "go",
            },
            highlight = { enable = true },
            indent = { enable = true },
        })
    end,
}

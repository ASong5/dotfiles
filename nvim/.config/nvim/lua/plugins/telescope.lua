return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = { "nvim-lua/plenary.nvim", "debugloop/telescope-undo.nvim" },
        config = function()
            local telescope = require("telescope")
            local utils = require("telescope.utils")
            local builtin = require("telescope.builtin")

            local find_files_with_fallback = function()
                -- We cache the results of "git rev-parse"
                -- Process creation is expensive in Windows, so this reduces latency
                local is_inside_work_tree = {}

                local opts = {} -- define here if you want to define something

                local cwd = vim.fn.getcwd()
                if is_inside_work_tree[cwd] == nil then
                    vim.fn.system("git rev-parse --is-inside-work-tree")
                    is_inside_work_tree[cwd] = vim.v.shell_error == 0
                end

                if is_inside_work_tree[cwd] then
                    builtin.git_files(opts)
                else
                    builtin.find_files(opts)
                end
            end

            telescope.setup({
                defaults = {
                    file_ignore_patterns = {
                        "node_modules",
                        "venv",
                    },
                },
                extensions = {
                    undo = {
                        mappings = {
                            i = {
                                ["<cr>"] = require("telescope-undo.actions").restore,
                                ["<S-cr>"] = require("telescope-undo.actions").yank_additions,
                                ["<C-cr>"] = require("telescope-undo.actions").yank_deletions,
                            },
                            n = {
                                ["<cr>"] = require("telescope-undo.actions").restore,
                                ["<S-cr>"] = require("telescope-undo.actions").yank_additions,
                                ["<C-cr>"] = require("telescope-undo.actions").yank_deletions,
                            },
                        },
                    },
                },
            })
            vim.keymap.set("n", "<leader>ff", find_files_with_fallback, {noremap = true, silent = true})
            vim.keymap.set("n", "<leader>fg", function()
                builtin.live_grep({ cwd = utils.buffer_dir() })
            end, {})
            vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
            require("telescope").load_extension("undo")
        end,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })
            require("telescope").load_extension("ui-select")
        end,
    },
}

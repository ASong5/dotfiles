return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            window = {
                position = "float"
            }
        })
        vim.keymap.set('n', '<leader>nt', ':Neotree filesystem toggle<CR>')

        vim.api.nvim_create_autocmd("BufEnter", {
            command = "set rnu nu",
        })
        vim.api.nvim_create_autocmd({'UIEnter'}, {
            callback = function(event)
                local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
                if client ~= nil and client.name == "Firenvim" then
                    vim.cmd("Neotree close")
                end
            end
        })
    end
}


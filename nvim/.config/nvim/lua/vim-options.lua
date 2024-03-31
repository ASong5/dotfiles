vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set autoindent")
vim.cmd("set smartindent")

-- uses fat cursor even in insert mode
vim.opt.guicursor = ""

-- opt for persistent undo tree over swapfiles
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim.undodir"
vim.opt.undofile = true

-- remove annoying search highlights but keep incremental search instead
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- good colors
vim.opt.termguicolors = true

-- vim.cmd("set updatetime=100")
vim.g.mapleader = " "

-- allow C-backspace to delete word
vim.api.nvim_set_keymap('i', '<C-H>', '<C-W>', {noremap = true, silent = true})

-- system clipboard copy
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+y")

vim.keymap.set("n", "<C-v>", "\"+p")
vim.keymap.set("v", "<C-v>", "\"+p")
vim.keymap.set("n", "<C-V>", "\"+p")

-- move selected up and down
vim.keymap.set("v", "<PageDown>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<PageUp>", ":m '<-2<CR>gv=gv")

-- keeps cursor in middle when going up/down a page or tabbing through search term
vim.keymap.set("n", "<s-up>", "<s-up>zz")
vim.keymap.set("n", "<S-Down>", "<S-Down>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "n", "Nzzzv")

-- doesnt overwrite copy buffer when pasting over text by sending the selected word to void buffer
vim.keymap.set("x", "<leader>p", "\"_dP")

-- keymap for visual block mode
vim.api.nvim_set_keymap("n", "<leader>v", "<C-V>", {noremap = true})

-- search and replace on cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]])


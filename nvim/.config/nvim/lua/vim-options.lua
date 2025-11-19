vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set autoindent")
vim.cmd("set smartindent")
vim.cmd("set ignorecase smartcase")
vim.cmd("set linebreak")

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

-- show line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- change tabs
vim.keymap.set("n", "<Tab>", "<Cmd>tabnext<CR>")
vim.keymap.set("n", "<S-Tab>", "<Cmd>tabprevious<CR>")

-- unmap shift+left/right to avoid redundancy with the native remaps below and to force myself to use more mnemonic binds
vim.keymap.set("n", "<C-Left>", "<Nop>", { noremap = true })
vim.keymap.set("n", "<C-Right>", "<Nop>", { noremap = true })
vim.keymap.set("i", "<C-Left>", "<Nop>", { noremap = true })
vim.keymap.set("i", "<C-Right>", "<Nop>", { noremap = true })

-- native vim operator/motion remaps. TODO figure out mappings for S and e/E since they are redundant with the current mappings
vim.keymap.set("n", "B", "ge", { noremap = true }) -- back to end of last word
vim.keymap.set("n", "W", "e", { noremap = true }) -- go to start of the line
-- Substitute (change) word
vim.keymap.set("n", "s", "ciw", { noremap = true })
vim.keymap.set("n", "S", "ciW", { noremap = true })
-- In operator-pending mode, map s to select inner word
vim.keymap.set("o", "s", "iw", { noremap = true })
vim.keymap.set("o", "S", "iW", { noremap = true })
-- In visual mode too (for consistency)
vim.keymap.set("x", "s", "iw", { noremap = true })
vim.keymap.set("x", "S", "iW", { noremap = true })

-- follow and unfollow tag with Enter and Backspace keys only in man and help pages
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "man", "help" },
	callback = function()
		vim.keymap.set("n", "<CR>", "<C-]>", { buffer = true, silent = true })
		vim.keymap.set("n", "<BS>", "<C-t>", { buffer = true, silent = true })
	end,
})

-- jump back and forth through jump-list with Enter and Backspace keys
vim.keymap.set("n", "<CR>", "<C-i>", { noremap = true, silent = true })
vim.keymap.set("n", "<BS>", "<C-o>", { noremap = true, silent = true })

-- remap to go backwards in the jump-list with backspace
-- vim.keymap.set("n", "<BS>€kl", "<C-o>", { noremap = true, silent = true })

-- redo command
vim.keymap.set("n", "U", "<C-r>")

-- vim.cmd("set updatetime=100")
vim.g.mapleader = " "

-- allow C-backspace to delete word
vim.api.nvim_set_keymap("i", "<C-H>", "<C-W>", { noremap = true, silent = true })

-- save/exit/save and exit keybinds
vim.keymap.set("n", "<leader>ww", ":w<CR>")
vim.keymap.set("n", "<leader>wa", ":wa<CR>")
vim.keymap.set("n", "<leader>xx", ":x<CR>")
vim.keymap.set("n", "<leader>xa", ":xa<CR>")
vim.keymap.set("n", "<leader>qq", ":q!<CR>")
vim.keymap.set("n", "<leader>qa", ":qa!<CR>")

-- select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G")

-- system clipboard copy
vim.api.nvim_set_keymap("n", "<C-c>", '"+yy', { noremap = true })
vim.api.nvim_set_keymap("v", "<C-c>", '"+y', { noremap = true })
vim.keymap.set("n", "<C-v>", '"+p')
vim.keymap.set("v", "<C-v>", '"+p')

-- doesnt overwrite copy buffer when pasting over text by sending the selected word to void buffer
vim.keymap.set("n", "<leader>p", '"_dP')

-- move selected up and down
vim.keymap.set("v", "<PageDown>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<PageUp>", ":m '<-2<CR>gv=gv")

-- keeps cursor in middle when going up/down a page or tabbing through search term
vim.keymap.set("n", "<S-Up>", "<C-u>zz")
vim.keymap.set("n", "<S-Down>", "<C-d>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "n", "Nzzzv")

-- keymap for visual block mode
vim.api.nvim_set_keymap("n", "<leader>v", "<C-V>", { noremap = true })

-- search and replace on cursor
vim.keymap.set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]])
vim.keymap.set("v", "<leader>sr", [[:s/\<<C-r><C-w>\>//gI<Left><Left><Left>]])

-- get help page for expression under cursor, if not find search word
vim.keymap.set("n", "<leader>h", function()
	local expr = vim.fn.expand("<cexpr>")
	-- try with the full expression first
	local ok, _ = pcall(vim.cmd, "help " .. expr)
	if not ok then
		-- fallback to just the word under cursor
		local word = vim.fn.expand("<cword>")
		ok, _ = pcall(vim.cmd, "help " .. word)
		if not ok then
			vim.notify("No help found for: " .. expr, vim.log.levels.WARN)
		end
	end
end, { desc = "Help for expression under cursor" })

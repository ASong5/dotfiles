return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"cssls",
					"clangd",
					"html",
					"jsonls",
					"ts_ls",
					"ruff",
					"pyright",
				},
				automatic_enable = {
					exclude = {
						"jdtls", -- Exclude jdtls from automatic setup
					},
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local telescope = require("telescope.builtin")
			local lsp = vim.lsp

			lsp.config("lua_ls", {
				settings = { diagnostics = { globals = { "vim" } } },
				capabilities = capabilities,
			})
			lsp.config("cssls", {
				capabilities = capabilities,
			})
			lsp.config("clangd", {
				capabilities = capabilities,
			})
			lsp.config("html", {
				capabilities = capabilities,
			})
			lsp.config("jsonls", {
				capabilities = capabilities,
			})
			lsp.config("ts_ls", {
				capabilities = capabilities,
			})
			lsp.config("ruff", {
				capabilities = capabilities,
			})
			lsp.config("rust_analyzer", {
				capabilities = capabilities,
			})
			lsp.config("bashls", {
				capabilities = capabilities,
			})
			lsp.config("pyright", {
				capabilities = capabilities,
				settings = {
					pyright = {
						-- Using Ruff's import organizer
						disableOrganizeImports = true,
					},
					python = {
						analysis = {
							-- Ignore all files for analysis to exclusively use Ruff for linting
							ignore = { "*" },
						},
					},
				},
			})

			vim.diagnostic.config({
				update_in_insert = true,
				float = { border = "rounded", focusable = true },
			})

			vim.keymap.set("n", "K", function()
				vim.lsp.buf.hover({ border = "rounded", title = "Details" })
			end, {})
			vim.keymap.set("n", "E", vim.diagnostic.open_float, {})
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
			vim.keymap.set("n", "gr", telescope.lsp_references, {})
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
			vim.keymap.set("n", "ge", function()
				vim.diagnostic.jump({
					count = 1,
					severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
				})
			end, {})
			vim.keymap.set("n", "gE", function()
				vim.diagnostic.jump({
					count = -1,
					severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
				})
			end, {})
			vim.keymap.set("n", "<leader>fe", telescope.diagnostics, {})
			vim.keymap.set("n", "<leader>kd", vim.lsp.buf.format, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		config = function()
			require("lsp_lines").setup()
		end,
	},
	{
		"mfussenegger/nvim-jdtls",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
			local bundles = {
				vim.fn.glob(
					"/home/pundrew/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
					1
				),
			}
			local workspace_dir = "/home/pundrew/git/Projects/Java/" .. project_name
			local config = {
				capabilities = capabilities,
				-- The command that starts the language server
				-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
				cmd = {

					-- 💀
					"/usr/bin/java", -- or '/path/to/java17_or_newer/bin/java'
					-- depends on if `java` is in your $PATH env variable and if it points to the right version.

					"-Declipse.application=org.eclipse.jdt.ls.core.id1",
					"-Dosgi.bundles.defaultStartLevel=4",
					"-Declipse.product=org.eclipse.jdt.ls.core.product",
					"-Dlog.protocol=true",
					"-Dlog.level=ALL",
					"-Xmx1g",
					"--add-modules=ALL-SYSTEM",
					"--add-opens",
					"java.base/java.util=ALL-UNNAMED",
					"--add-opens",
					"java.base/java.lang=ALL-UNNAMED",

					-- 💀
					"-jar",
					"/home/pundrew/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_1.7.0.v20250519-0528.jar",
					-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
					-- Must point to the                                                     Change this to
					-- eclipse.jdt.ls installation                                           the actual version

					-- 💀
					"-configuration",
					"/home/pundrew/.local/share/nvim/mason/packages/jdtls/config_linux",
					-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
					-- Must point to the                      Change to one of `linux`, `win` or `mac`
					-- eclipse.jdt.ls installation            Depending on your system.

					-- 💀
					-- See `data directory configuration` section in the README
					"-data",
					workspace_dir,
				},

				-- 💀
				-- This is the default if not provided, you can remove it. Or adjust as needed.
				-- One dedicated LSP server & client will be started per unique root_dir
				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),

				-- Here you can configure eclipse.jdt.ls specific settings
				-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
				-- for a list of options
				settings = {
					java = {
						completion = { guessMethodArguments = true },
						signatureHelp = { enabled = true },
					},
				},

				on_attach = function(client, bufnr)
					require("jdtls").setup_dap({ hotcodereplace = "auto" })
					require("jdtls.dap").setup_dap_main_class_configs()
				end,

				-- Language server `initializationOptions`
				-- You need to extend the `bundles` with paths to jar files
				-- if you want to use additional eclipse.jdt.ls plugins.
				--
				-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
				--
				-- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this

				init_options = {
					bundles = bundles,
				},
			}
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function(args)
					-- This starts a new client & server,
					-- or attaches to an existing client & server depending on the `root_dir`.
					require("jdtls").start_or_attach(config)
				end,
			})
		end,
	},
}

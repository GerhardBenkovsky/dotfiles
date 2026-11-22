return {
	{
		"mason-org/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			ensure_installed = { "lua_ls", "ts_ls", "yamlls", "helm_ls", "groovyls" },
			automatic_enable = { "lua_ls", "ts_ls", "yamlls", "helm_ls", "groovyls" },
		},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
	{
		-- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },
		},

		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})

			vim.lsp.config("ts_ls", {
				capabilities = capabilities,
			})

			vim.lsp.config("yamlls", {
				capabilities = capabilities,
				-- Helm handles its own values files and delegates YAML support internally.
				filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
				on_attach = require("infrastructure").update_yaml_schema,
				settings = {
					yaml = {
						format = { enable = false }, -- Conform/Prettier owns formatting.
						validate = true,
						completion = true,
						hover = true,
						schemaStore = { enable = true },
						schemas = {
							["https://json.schemastore.org/github-workflow.json"] = {
								"**/.github/workflows/*.yml",
								"**/.github/workflows/*.yaml",
							},
							["https://json.schemastore.org/github-action.json"] = {
								"**/action.yml",
								"**/action.yaml",
							},
							["https://json.schemastore.org/chart.json"] = "**/Chart.yaml",
							kubernetes = {},
						},
					},
				},
			})
			vim.lsp.config("helm_ls", {
				capabilities = capabilities,
				settings = {
					["helm-ls"] = {
						yamlls = {
							path = "yaml-language-server",
							config = {
								format = { enable = false },
								schemas = { kubernetes = "templates/**" },
							},
						},
					},
				},
			})
			vim.lsp.config("groovyls", { capabilities = capabilities })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
				callback = function(args)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
					end
					local function picker(name)
						return function()
							require("telescope.builtin")[name]()
						end
					end

					-- Jump to the definition of the word under your cursor.
					--  This is where a variable was first declared, or where a function is defined, etc.
					--  To jump back, press <C-T>.
					map("gd", picker("lsp_definitions"), "[G]oto [D]efinition")

					-- Find references for the word under your cursor.
					map("gr", picker("lsp_references"), "[G]oto [R]eferences")

					-- Jump to the implementation of the word under your cursor.
					--  Useful when your language has ways of declaring types without an actual implementation.
					map("gI", picker("lsp_implementations"), "[G]oto [I]mplementation")

					-- Jump to the type of the word under your cursor.
					--  Useful when you're not sure what type a variable is and you want to see
					--  the definition of its *type*, not where it was *defined*.
					map("<leader>D", picker("lsp_type_definitions"), "Type [D]efinition")

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					map("<leader>ds", picker("lsp_document_symbols"), "[D]ocument [S]ymbols")

					-- Fuzzy find all the symbols in your current workspace
					--  Similar to document symbols, except searches over your whole project.
					map("<leader>ws", picker("lsp_dynamic_workspace_symbols"), "[W]orkspace [S]ymbols")

					-- Rename the variable under your cursor
					--  Most Language Servers support renaming across files, etc.
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

					-- Opens a popup that displays documentation about the word under your cursor
					--  See `:help K` for why this keymap
					map("K", vim.lsp.buf.hover, "Hover Documentation")

					-- WARN: This is not Goto Definition, this is Goto Declaration.
					--  For example, in C this would take you to the header
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				end,
			})
		end,
	},
}

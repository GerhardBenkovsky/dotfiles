return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	keys = {
		{
			"<leader>cf",
			function()
				if vim.bo.filetype == "helm" then
					vim.notify("Helm template formatting is disabled to protect Go-template syntax")
					return
				end
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "x" },
			desc = "[C]ode [F]ormat",
		},
	},
	opts = {
		format_on_save = function(bufnr)
			if vim.bo[bufnr].filetype == "helm" then
				return
			end
			return { timeout_ms = 1000, lsp_format = "fallback" }
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "goimports", "gofumpt" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			yaml = { "prettier" },
			["yaml.helm-values"] = { "prettier" },
		},
	},
}

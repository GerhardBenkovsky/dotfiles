return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { { "mason-org/mason.nvim", opts = {} } },
	opts = {
		ensure_installed = { "stylua", "goimports", "gofumpt", "prettier", "actionlint" },
		auto_update = false,
		run_on_start = true,
		integrations = {
			["mason-lspconfig"] = false,
			["mason-null-ls"] = false,
			["mason-nvim-dap"] = false,
		},
	},
}

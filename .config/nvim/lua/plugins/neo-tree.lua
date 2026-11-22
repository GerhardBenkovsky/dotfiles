return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	cmd = "Neotree",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<C-n>", "<cmd>Neotree filesystem toggle left<CR>", desc = "Toggle file tree" },
		{ "<leader>bf", "<cmd>Neotree buffers reveal float<CR>", desc = "Reveal bu[f]fers" },
	},
	opts = {},
}

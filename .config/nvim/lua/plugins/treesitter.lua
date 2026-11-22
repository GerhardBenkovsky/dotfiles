return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	opts = {},
	config = function(_, opts)
		local treesitter = require("nvim-treesitter")
		treesitter.setup(opts)
		treesitter.install({
			"bash",
			"html",
			"lua",
			"markdown",
			"markdown_inline",
			"go",
			"gomod",
			"gowork",
			"gosum",
			"javascript",
			"typescript",
			"tsx",
			"json",
			"yaml",
			"helm",
			"groovy",
			"vim",
			"vimdoc",
		})

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-features", { clear = true }),
			callback = function(args)
				if vim.bo[args.buf].buftype ~= "" then
					return
				end
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				local ok, loaded = pcall(vim.treesitter.language.add, lang or "")
				if ok and loaded then
					vim.treesitter.start(args.buf, lang)
					if vim.treesitter.query.get(lang, "indents") then
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end
			end,
		})
	end,
}

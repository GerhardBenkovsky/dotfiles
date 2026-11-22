return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local function lint_workflow(args)
			local path = vim.api.nvim_buf_get_name(args.buf)
			if path:match("/%.github/workflows/[^/]+%.ya?ml$") and vim.fn.executable("actionlint") == 1 then
				vim.api.nvim_buf_call(args.buf, function()
					-- Explicit selection keeps this linter away from other YAML files.
					require("lint").try_lint("actionlint")
				end)
			end
		end
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = vim.api.nvim_create_augroup("workflow-lint", { clear = true }),
			callback = lint_workflow,
		})
		lint_workflow({ buf = vim.api.nvim_get_current_buf() })
	end,
}

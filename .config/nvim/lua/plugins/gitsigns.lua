return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		on_attach = function(bufnr)
			local gs = require("gitsigns")
			local function map(mode, keys, func, desc)
				vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "Git: " .. desc })
			end
			for keys, direction in pairs({ ["]c"] = "next", ["[c"] = "prev" }) do
				map("n", keys, function()
					if vim.wo.diff then
						vim.cmd.normal({ keys, bang = true })
					else
						gs.nav_hunk(direction)
					end
				end, direction .. " hunk")
			end
			map("n", "<leader>hs", gs.stage_hunk, "[H]unk [S]tage/unstage")
			map("x", "<leader>hs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "[H]unk [S]tage/unstage selection")
			map("n", "<leader>hp", gs.preview_hunk, "[H]unk [P]review")
			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, "[H]unk line [B]lame")
			map("n", "<leader>hd", gs.diffthis, "[H]unk [D]iff")
			map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
		end,
	},
}

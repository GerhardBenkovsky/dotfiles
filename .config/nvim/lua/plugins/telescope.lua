local function picker(name, opts)
	return function()
		require("telescope.builtin")[name](opts)
	end
end

return {
	-- Fuzzy Finder (files, lsp, etc)
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	branch = "0.1.x",
	keys = {
		{ "<leader>sh", picker("help_tags"), desc = "[S]earch [H]elp" },
		{ "<leader>sk", picker("keymaps"), desc = "[S]earch [K]eymaps" },
		{ "<leader>sf", picker("find_files"), desc = "[S]earch [F]iles" },
		{ "<leader>ss", picker("builtin"), desc = "[S]earch [S]elect Telescope" },
		{ "<leader>sw", picker("grep_string"), desc = "[S]earch current [W]ord" },
		{ "<leader>sg", picker("live_grep"), desc = "[S]earch by [G]rep" },
		{ "<leader>sd", picker("diagnostics"), desc = "[S]earch [D]iagnostics" },
		{ "<leader>sr", picker("resume"), desc = "[S]earch [R]esume" },
		{ "<leader>s.", picker("oldfiles"), desc = "[S]earch Recent Files" },
		{ "<leader><leader>", picker("buffers"), desc = "Find existing buffers" },
		{
			"<leader>/",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find(
					require("telescope.themes").get_dropdown({ winblend = 10, previewer = false })
				)
			end,
			desc = "[/] Fuzzily search in current buffer",
		},
		{
			"<leader>s/",
			picker("live_grep", { grep_open_files = true, prompt_title = "Live Grep in Open Files" }),
			desc = "[S]earch [/] in Open Files",
		},
		{
			"<leader>sn",
			picker("find_files", { cwd = vim.fn.stdpath("config") }),
			desc = "[S]earch [N]eovim files",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ -- If encountering errors, see telescope-fzf-native README for install instructions
			"nvim-telescope/telescope-fzf-native.nvim",

			-- `build` is used to run some command when the plugin is installed/updated.
			-- This is only run then, not every time Neovim starts up.
			build = "make",

			-- `cond` is a condition used to determine whether this plugin should be
			-- installed and loaded.
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },

		-- Useful for getting pretty icons, but requires a Nerd Font.
		{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
	},
	opts = function()
		return {
			extensions = {
				["ui-select"] = require("telescope.themes").get_dropdown(),
			},
		}
	end,
	config = function(_, opts)
		-- Telescope is a fuzzy finder that comes with a lot of different things that
		-- it can fuzzy find! It's more than just a "file finder", it can search
		-- many different aspects of Neovim, your workspace, LSP, and more!
		--
		-- The easiest way to use telescope, is to start by doing something like:
		--  :Telescope help_tags
		--
		-- After running this command, a window will open up and you're able to
		-- type in the prompt window. You'll see a list of help_tags options and
		-- a corresponding preview of the help.
		--
		-- Two important keymaps to use while in telescope are:
		--  - Insert mode: <c-/>
		--  - Normal mode: ?
		--
		-- This opens a window that shows you all of the keymaps for the current
		-- telescope picker. This is really useful to discover what Telescope can
		-- do as well as how to actually do it!
		--
		-- See `:help telescope` and `:help telescope.setup()`
		require("telescope").setup(opts)

		-- Enable telescope extensions, if they are installed
		pcall(require("telescope").load_extension, "fzf")
		pcall(require("telescope").load_extension, "ui-select")
	end,
}

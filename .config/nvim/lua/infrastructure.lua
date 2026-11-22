local M = {}

local function chart_root(path)
	local chart = vim.fs.find("Chart.yaml", { path = vim.fs.dirname(path), upward = true })[1]
	return chart and vim.fs.dirname(chart)
end

function M.setup()
	vim.filetype.add({
		pattern = {
			[".*/templates/.*"] = {
				function(path)
					local root = chart_root(path)
					if root and path:sub(1, #root + 11) == root .. "/templates/" then
						return "helm"
					end
				end,
				{ priority = 100 },
			},
			[".*/values[^/]*%.ya?ml"] = {
				function(path)
					if chart_root(path) then
						return "yaml.helm-values"
					end
				end,
				{ priority = 100 },
			},
			[".*/Jenkinsfile[^/]*"] = "groovy",
		},
		filename = { Jenkinsfile = "groovy" },
	})
	vim.treesitter.language.register("yaml", "yaml.helm-values")

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("infrastructure-schemas", { clear = true }),
		callback = function(args)
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf, name = "yamlls" })) do
				M.update_yaml_schema(client, args.buf)
			end
		end,
	})
end

-- Recognize manifests by their top-level fields, not by a blanket *.yaml schema.
-- Explicit modelines remain available for CRDs and version-specific schemas.
function M.update_yaml_schema(client, bufnr)
	local api_version, kind, explicit_schema = false, false, false
	for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
		api_version = api_version or line:match("^apiVersion:%s*%S") ~= nil
		kind = kind or line:match("^kind:%s*%S") ~= nil
		explicit_schema = explicit_schema or line:find("yaml-language-server:", 1, true) ~= nil
	end
	local uri = vim.uri_from_bufnr(bufnr)
	local schemas = client.settings.yaml.schemas
	local manifests = schemas.kubernetes or {}
	local filtered = vim.tbl_filter(function(path)
		return path ~= uri
	end, manifests)
	if api_version and kind and not explicit_schema then
		table.insert(filtered, uri)
	end
	if not vim.deep_equal(manifests, filtered) then
		schemas.kubernetes = filtered
		client:notify("workspace/didChangeConfiguration", { settings = client.settings })
	end
end

return M

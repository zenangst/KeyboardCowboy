local workspace = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))

for key, directory in pairs({
	a = "Service/Sources",
	c = "Components",
	e = "Editor/Sources",
	f = "Features",
	k = "Triggers",
}) do
	vim.keymap.set("n", "<leader>j" .. key, function()
		require("oil").open_float(vim.fs.joinpath(workspace, directory))
	end, { desc = "Open v4 " .. directory .. " in Oil" })
end

local function package_root()
	local path = vim.api.nvim_buf_get_name(0)
	if vim.bo.filetype == "oil" then
		path = require("oil").get_current_dir() or ""
	end
	if path == "" then
		path = vim.fn.getcwd()
	end

	local root = vim.fs.root(path, "Package.swift")
	if root and (root == workspace or vim.startswith(root, workspace .. "/")) then
		return root
	end
end

local function jump_to_tmp()
	local path = vim.fs.joinpath(package_root() or workspace, "tmp")
	if vim.fn.isdirectory(path) == 0 then
		vim.notify("No tmp directory at " .. path, vim.log.levels.WARN)
		return
	end
	require("oil").open_float(path)
end

local tmp_desc = "Open package or v4 tmp/ in Oil"
vim.keymap.set("n", "<leader>jz", jump_to_tmp, { desc = tmp_desc })

local group = vim.api.nvim_create_augroup("KeyboardCowboyPackageJumps", { clear = true })
local function set_jumps()
	if not package_root() then
		return
	end

	vim.keymap.set("n", "<leader>jz", jump_to_tmp, { buffer = true, desc = tmp_desc })
	for key, target in pairs({ s = "Sources", t = "Tests", p = "Package.swift" }) do
		vim.keymap.set("n", "<leader>j" .. key, function()
			local root = package_root()
			local path = root and vim.fs.joinpath(root, target)
			if not path or not vim.uv.fs_stat(path) then
				vim.notify("No " .. target .. " in the current Swift package", vim.log.levels.WARN)
				return
			end
			require("oil").open_float(path)
		end, { buffer = true, desc = "Open package " .. target .. " in Oil" })
	end
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "DirChanged" }, {
	group = group,
	callback = set_jumps,
})
set_jumps()

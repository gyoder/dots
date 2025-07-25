--
-- nvim init script by grace
--

-- Get hostname
local handle = io.popen("hostname")
local hostname = handle:read("*a") or ""
handle:close()
hostname = hostname:gsub("%s+", "")
vim.g.hostname = hostname
if string.match(hostname, "cs.purdue.edu") then
  vim.g.is_purdue = true
else
  vim.g.is_purdue = false
end

-- add required things to path
if vim.g.is_purdue then
  vim.env.PATH = vim.env.PATH .. ':' .. os.getenv("HOME") .. '/clangd/bin:/u/riker/u98/cs240/bin'
end

require("plugins")
require("native-lsp")
require("diagnostics")
require("remap")


if vim.g.is_purdue then
  require("westwood-lint")
end
require("standard-lint")

vim.cmd("source ~/.vim/settings.vim")

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})


-- File IO can be slow and this might help idk
if vim.g.is_purdue then
  vim.cmd("set noundofile") -- i forgor how to do this in lua so i didnt
end

--
-- vim.opt.spell = true
-- vim.opt.spelllang = "en_us"
--

-- For init.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.textwidth = 80
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.o.clipboard = "unnamedplus"

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
    local osc52 = require("vim.ui.clipboard.osc52")
    local contents = vim.v.event.regcontents
    local regtype = vim.v.event.regtype

    if type(contents) == "string" then
      contents = { contents }
    end

    if regtype == "V" then
      for i, line in ipairs(contents) do
        contents[i] = line .. "\n"
      end
    end

    osc52.copy("+")(contents)
    osc52.copy("*")(contents)
  end,
})

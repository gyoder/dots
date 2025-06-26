--
-- nvim init script by grace
--

-- Get hostname
local hostname = vim.fn.hostname()
hostname = hostname:gsub("%s+", "")
vim.g.hostname = hostname
vim.g.is_purdue = string.match(hostname, "cs.purdue.edu") ~= nil

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
  vim.o.undofile = false
end






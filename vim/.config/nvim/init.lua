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
  -- require("westwood-lint")
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

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.textwidth = 80
    vim.opt_local.formatoptions = "atcqjnl"
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true

    -- Show column guide
    vim.opt_local.colorcolumn = "80"
  end,
})

-- Typst configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = function()
    -- Line wrapping settings
    vim.opt_local.textwidth = 80
    vim.opt_local.formatoptions = "tcqjnl"
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    -- Show column guide
    vim.opt_local.colorcolumn = "80"

    -- Toggle 'a' in formatoptions
    vim.keymap.set("n", "<leader>a", function()
      local fo = vim.opt_local.formatoptions:get()
      if fo.a then
        vim.opt_local.formatoptions:remove("a")
        print("Auto-formatting disabled")
      else
        vim.opt_local.formatoptions:append("a")
        print("Auto-formatting enabled")
      end
    end, { buffer = true, desc = "Toggle auto-formatting" })
  end,
})
-- Setup formatting on LSP attach
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--
--     if client and client.supports_method("textDocument/formatting") then
--       vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
--         buffer = args.buf,
--         callback = function()
--           vim.lsp.buf.format({
--             async = true,
--             bufnr = args.buf,
--           })
--         end,
--       })
--     end
--   end,
-- })

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.o.clipboard = "unnamedplus"

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
-- stupid hacky workaround to make it so i can paste from tmux with OSC52
-- https://github.com/neovim/neovim/discussions/29350#discussioncomment-10299517
-- tracking issue about tmux behavior: https://github.com/tmux/tmux/issues/4275
if vim.env.TMUX ~= nil then
  local copy = { 'tmux', 'load-buffer', '-w', '-' }
  local paste = { 'bash', '-c', 'tmux refresh-client -l && sleep 0.05 && tmux save-buffer -' }
  vim.g.clipboard = {
    name = 'tmux',
    copy = {
      ['+'] = copy,
      ['*'] = copy,
    },
    paste = {
      ['+'] = paste,
      ['*'] = paste,
    },
    cache_enabled = 0,
  }
end


if vim.treesitter.language.ft_to_lang == nil then
  vim.treesitter.language.ft_to_lang = function(ft)
    return ft
  end
end

-- https://simondalvai.org/blog/godot-neovim/
require("godot")

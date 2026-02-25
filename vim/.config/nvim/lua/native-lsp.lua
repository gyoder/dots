vim.lsp.config('luals', {
  on_attach = function()
    print('luals is now active in this file')
  end,
})
if not string.match(vim.g.hostname, "cs.purdue.edu") then
  vim.lsp.enable("luals")
end


vim.lsp.config('pyright', {
  on_attach = function()
    print('pyright is now active in this file')
  end,
})

vim.lsp.enable("pyright")
-- vim.lsp.enable("basedpyright")

vim.lsp.config('ty', {
  on_attach = function()
    print('ty is now active in this file')
  end,
})

-- vim.lsp.enable("ty")



vim.lsp.config('clangd', {
  on_attach = function()
    print('clangd is now active in this file')
  end,
})

vim.lsp.enable("clangd")

vim.lsp.config('tailwind-ls', {
  on_attach = function()
    print('tailwind-ls is now active in this file')
  end,
})

vim.lsp.enable("tailwind-ls")

vim.lsp.config('zls', {
  on_attach = function()
    print('zls is now active in this file')
  end,
})

vim.lsp.enable("zls")
-- vim.lsp.enable("zigscient")

vim.lsp.enable("gopls")

vim.lsp.enable("tinymist")

vim.lsp.enable("cspell-ls")

vim.lsp.enable("astro")

vim.lsp.config('rust_analyzer', {
  on_attach = function()
    print('rust-analyzer is now active in this file')
  end,
})

vim.lsp.enable("rust-analyzer")
vim.lsp.enable("gdscript")
vim.lsp.config('csharp-ls', {
  on_attach = function()
    print('csharp-ls is now active in this file')
  end,
})


vim.lsp.enable("csharp-ls")

vim.lsp.enable("asm-lsp")
vim.lsp.enable("codebook")

-- https://lsp-zero.netlify.app/blog/lsp-client-features.html

vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'noinsert' }
vim.opt.shortmess:append('c')


vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp", { clear = true }),
  callback = function(args)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = args.buf,
      callback = function()
        if vim.bo[args.buf].filetype == "typst" or vim.bo[args.buf].filetype == "c" then
          return
        end
        vim.lsp.buf.format({ async = false, id = args.data.client_id })
      end,
    })
  end
})

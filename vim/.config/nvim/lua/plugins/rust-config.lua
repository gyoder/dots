local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set(
  "n",
  "<leader>a",
  function()
    vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
    -- or vim.lsp.buf.codeAction() if you don't want grouping.
  end,
  { silent = true, buffer = bufnr }
)
vim.keymap.set(
  "n",
  "K",
  function()
    if vim.bo.filetype == "rust" then
      vim.cmd.RustLsp({'hover', 'actions'})
    else
      vim.lsp.buf.hover()
    end
  end,
  { silent = true, buffer = bufnr }
)

vim.g.rustaceanvim = {
  server = {
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  },
}

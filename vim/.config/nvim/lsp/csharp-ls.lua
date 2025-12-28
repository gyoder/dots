---@type vim.lsp.Config
return {
  cmd = { 'csharp-ls' },
  root_markers = { ".git" },
  filetypes = { 'cs' },
  init_options = {
    AutomaticWorkspaceInit = true,
  },
}

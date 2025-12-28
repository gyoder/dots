---@brief
---
--- [cspell language server](https://github.com/vlabo/cspell-lsp)
---
return {
  cmd = { 'cspell-lsp', '--stdio' },
  filetypes = { "go", "rust", "js", "ts", "html", "css", "json", "yaml", "markdown", "gitcommit", "typst", "lua", "htmlua", "c", "cpp", "arduino" },
  root_markers = {
    '.git',
    'cspell.json',
    '.cspell.json',
    'cspell.json',
    '.cSpell.json',
    'cSpell.json',
    'cspell.config.js',
    'cspell.config.cjs',
    'cspell.config.json',
    'cspell.config.yaml',
    'cspell.config.yml',
    'cspell.yaml',
    'cspell.yml',
  },
  init_options = {
    userWordsFile = vim.fn.expand('~/.config/cspell/user-dictionary.txt'),
    configPaths = {
      vim.fn.expand('~/.cspell.json'),
    },
  },
}

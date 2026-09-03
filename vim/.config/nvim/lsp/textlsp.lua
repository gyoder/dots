return {
  cmd = {"textlsp"}, -- You may need to provide the full path to textlsp if not in $PATH
  filetypes = { "markdown", "org", "latex", "txt", "md", "markdown" }, -- and any other you want as plain text
  root_markers = {
    ".git",
  },
  single_file_support = true,
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    -- textLSP does not require offsetEncoding, but you may include it for consistency:
    offsetEncoding = { "utf-8", "utf-16" },
  },
  settings = {
    textLSP = {
      analysers = {
        languagetool = {
          enabled = false,
          -- check_text = {
          --   on_open = true,
          --   on_save = true,
          --   on_change = false,
          -- },
        },
        ollama = {
          enabled = true,
          check_text = {
            on_open = false,
            on_save = true,
            on_change = false,
          },
          model = "phi3:3.8b-instruct",
          max_token = 50,
        },
        -- enable and configure other analyzers as desired
      },
      documents = {
        language = "auto:en",
        min_length_language_detect = 20,
        org = { org_todo_keywords = { "TODO", "IN_PROGRESS", "DONE" } },
        txt = { parse = true },
      },
    },
  },
}

return {
	cmd = { "rust-analyzer" },
  filetypes = { "rust", "rs" },
  root_markers = { "Cargo.lock" },
  settings = {
    ["rust-analyzer"] = {
			check = {
				command = "clippy",
			},
			diagnostics = {
				enable = true,
			},
		},
	},
}

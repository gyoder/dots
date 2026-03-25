-- vim.pack.update(nil, { target = 'lockfile' })

return require("packed").setup(function(use)
  use 'nvim-lua/plenary.nvim'
  use {
    'nvim-telescope/telescope.nvim',
    config = function()
      require('telescope').setup({
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--glob=!node_modules/**",
            "--glob=!build/**",
          },
          file_ignore_patterns = { "node_modules", "build" },
        },
      })
    end,
  }

  -- https://tduyng.com/blog/neovim-highlight-syntax/
  use {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    config = function()
      local parser_path = vim.fn.expand("~/.local/share/nvim/site")
      vim.opt.runtimepath:append(parser_path)

      require("nvim-treesitter").setup({})
      require("nvim-treesitter").install({
        "bash",
        "blade",
        "c",
        "comment",
        "css",
        "diff",
        "dockerfile",
        "fish",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "html",
        "ini",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "make",
        "markdown",
        "markdown_inline",
        "nginx",
        "nix",
        "proto",
        "python",
        "query",
        "regex",
        "rust",
        "scss",
        "sql",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "zig",
      })

      vim.api.nvim_create_autocmd("PackChanged", {
        desc = "Handle nvim-treesitter updates",
        group = vim.api.nvim_create_augroup("nvim-treesitter-pack-changed-update-handler", { clear = true }),
        callback = function(event)
          if event.data.kind == "update" then
            local ok = pcall(vim.cmd, "TSUpdate")
            if ok then
              vim.notify("TSUpdate completed successfully!", vim.log.levels.INFO)
            else
              vim.notify("TSUpdate command not available yet, skipping", vim.log.levels.WARN)
            end
          end
        end,
      })

      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "*" },
        callback = function()
          local filetype = vim.bo.filetype
          if filetype and filetype ~= "" then
            local success = pcall(function()
              vim.treesitter.start()
            end)
            if not success then
              return
            end
          end
        end,
      })
    end
  }

  use {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    version = "main",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          enable = true,
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V",  -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
          },
          include_surrounding_whitespace = false,
        },
        move = {
          enable = true,
          set_jumps = true,
        },
      })

      -- SELECT keymaps
      local sel = require("nvim-treesitter-textobjects.select")
      for _, map in ipairs({
        { { "x", "o" }, "af", "@function.outer" },
        { { "x", "o" }, "if", "@function.inner" },
        { { "x", "o" }, "ac", "@class.outer" },
        { { "x", "o" }, "ic", "@class.inner" },
        { { "x", "o" }, "aa", "@parameter.outer" },
        { { "x", "o" }, "ia", "@parameter.inner" },
        { { "x", "o" }, "ad", "@comment.outer" },
        { { "x", "o" }, "as", "@statement.outer" },
      }) do
        vim.keymap.set(map[1], map[2], function()
          sel.select_textobject(map[3], "textobjects")
        end, { desc = "Select " .. map[3] })
      end

      -- MOVE keymaps
      local mv = require("nvim-treesitter-textobjects.move")
      for _, map in ipairs({
        { { "n", "x", "o" }, "]]", mv.goto_next_start,     "@function.outer" },
        { { "n", "x", "o" }, "[[", mv.goto_previous_start, "@function.outer" },
        { { "n", "x", "o" }, "]f", mv.goto_next_start,     "@function.outer" },
        { { "n", "x", "o" }, "[f", mv.goto_previous_start, "@function.outer" },
        { { "n", "x", "o" }, "]c", mv.goto_next_start,     "@class.outer" },
        { { "n", "x", "o" }, "[c", mv.goto_previous_start, "@class.outer" },
        { { "n", "x", "o" }, "]F", mv.goto_next_end,       "@function.outer" },
        { { "n", "x", "o" }, "[F", mv.goto_previous_end,   "@function.outer" },
        { { "n", "x", "o" }, "]o", mv.goto_next_start,     { "@loop.inner", "@loop.outer" } },
        { { "n", "x", "o" }, "[o", mv.goto_previous_start, { "@loop.inner", "@loop.outer" } },
      }) do
        local modes, lhs, fn, query = map[1], map[2], map[3], map[4]
        -- build a human-readable desc
        local qstr = (type(query) == "table") and table.concat(query, ",") or query
        vim.keymap.set(modes, lhs, function()
          fn(query, "textobjects")
        end, { desc = "Move to " .. qstr })
      end
    end
  }



  use 'mbbill/undotree'
  use 'nvim-tree/nvim-web-devicons'
  use 'mfussenegger/nvim-lint'
  use {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('lualine').setup {
        options = { theme = "rose-pine" }
      }
    end
  }

  -- grrr why does neovim not have this?
  use {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup {}
    end
  }

  use { "akinsho/toggleterm.nvim", config = function()
    require("toggleterm").setup {
      size = 30
    }
    vim.keymap.set({ "n", "t", "v" }, "<leader>tt", require("toggleterm").toggle, { desc = "Toggle terminal" })
  end }
  use { 'nvim-telescope/telescope.nvim' }
  if vim.g.hostname == "turing" then
    use {
      'anurag3301/nvim-platformio.lua',
      config = function()
        require('platformio').setup({
          lsp = "ccls" --default: ccls, other option: clangd
          -- If you pick clangd, it also creates compile_commands.json
        })
      end
    }
  end

  use {
    "chentoast/marks.nvim",
    config = function() require('marks').setup() end
  }

  -- use { "MunifTanjim/nui.nvim" }

  use { 'rafamadriz/friendly-snippets' }
  use {
    'saghen/blink.cmp',
    version = 'v1.10.1',
    config = function()
      require("blink.cmp").setup({
        fuzzy = {
          implementation = "prefer_rust_with_warning",
          prebuilt_binaries = {
            download = true,
            force_version = "v1.*"
          },
        },
        keymap = { preset = "enter" },
      })
    end
  }

  use {
    'f-person/git-blame.nvim',
    config = function()
      require("gitblame").setup {
        gitblame_delay = 1
      }
    end
  }


  use {
    "mfussenegger/nvim-dap",

    config = function()
      local dap = require("dap")

      -- require('dap.ext.vscode').load_launchjs(nil, {
      --   node = { 'javascript', 'typescript' },
      --   python = { 'python' },
      --   go = { 'go' },
      --   codelldb = { 'c', 'cpp', 'rust' }
      -- })

      vim.keymap.set('n', '<M-u>', function() dap.continue() end, { desc = 'DAP: Continue' })
      vim.keymap.set('n', '<M-i>', function() dap.step_into() end, { desc = 'DAP: Step Into' })
      vim.keymap.set('n', '<M-o>', function() dap.step_out() end, { desc = 'DAP: Step Out' })
      vim.keymap.set('n', '<M-p>', function() dap.step_over() end, { desc = 'DAP: Step Over' })
      vim.keymap.set('n', '<M-b>', function() dap.toggle_breakpoint() end, { desc = 'DAP: Toggle Breakpoint' })
      vim.keymap.set('n', '<F5>', function() dap.continue() end)
      vim.keymap.set('n', '<F10>', function() dap.step_over() end)
      vim.keymap.set('n', '<F11>', function() dap.step_into() end)
      vim.keymap.set('n', '<F12>', function() dap.step_out() end)
      vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end)
      vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end)

      dap.adapters.codelldb = {
        type = "executable",
        command = "codelldb"
      }
      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }
    end
  }


  use {
    'stevearc/overseer.nvim',
    config = function() require('overseer').setup() end
  }
  use 'theHamsta/nvim-dap-virtual-text'
  use "nvim-neotest/nvim-nio"
  use {
    "rcarriga/nvim-dap-ui",
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end
  }

  use { "geigerzaehler/tree-sitter-jinja2" }

  use {
    "rose-pine/neovim",
    as = "rose-pine",
    config = function()
      require("rose-pine").setup({
        variant = "moon"
      })
      vim.cmd("colorscheme rose-pine")
    end
  }

  use {
    'chomosuke/typst-preview.nvim',
    config = function()
      require 'typst-preview'.setup {}
    end,
  }


  use({
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.api.nvim_create_user_command("MDPreviewInstall", function()
        vim.vim.fn["mkdp#util#install"]()
      end, {})
    end,
  })


  use {
    'LukasPietzschmann/telescope-tabs',
    config = function()
      require 'telescope-tabs'.setup {
        -- Your custom config :^)
      }
    end
  }
  use "HiPhish/rainbow-delimiters.nvim"


  ------------------------
end)

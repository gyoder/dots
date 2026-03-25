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


  use {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    config = function()
      require('nvim-treesitter').setup()

      require('nvim-treesitter').install({
        'c', 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline', 'go'
      }):wait()

      -- enable highlighting
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
          if ok and stats and stats.size > max_filesize then
            return
          end
          pcall(vim.treesitter.start)
        end,
      })
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
  use {
    'anurag3301/nvim-platformio.lua',
    config = function()
      if vim.g.hostname == "turing" then
        require('platformio').setup({
          lsp = "ccls" --default: ccls, other option: clangd
          -- If you pick clangd, it also creates compile_commands.json
        })
      end
    end
  }

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

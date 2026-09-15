{ pkgs, ... }:

let
  wRoots =
    roots:
    roots
    ++ [
      ".jj"
      ".git"
    ];

in
{
  home.packages = [
    pkgs.nerd-fonts.symbols-only
  ];

  xdg.configFile."helix/ignore".text = ''
    .git/
    node_modules/
    build/
  '';

  programs.helix = {
    enable = true;
    package = pkgs.helix;
    defaultEditor = false;
    settings = {
      theme = "grace_rose_pine";
      editor = {
        bufferline = "multiple";
        color-modes = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        default-yank-register = "+";
        cursorline = true;
        cursorcolumn = true;
        continue-comments = false;
        line-number = "relative";
        text-width = 100;
        soft-wrap = {
          enable = true;
          max-indent-retain = 40;
          wrap-at-text-width = true;
          wrap-indicator = " ";
        };
        indent-guides = {
          render = true;
          character = "┆";
        };
        lsp = {
          display-messages = true;
        };

        file-picker = {
          hidden = false;
          ignore = true;
          git-ignore = true;
          git-global = true;
          git-exclude = true;
        };

        statusline = {
          left = [
            "mode"
            "separator"
            "spinner"
            "version-control"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
          ];
          center = [ ];
          right = [
            "diagnostics"
            "workspace-diagnostics"
            "selections"
            "position-percentage"
            "position"
            "file-type"
          ];
          separator = "";
          mode = {
            normal = "  NOR ";
            insert = "  INS ";
            select = "  SEL ";
          };

        };
      };
      keys.normal = {
        "C-w" = "no_op";
        "C-r" = ":reload";
        y = "yank_to_clipboard";
        p = "paste_clipboard_after";
        P = "paste_clipboard_before";
        space = {
          t = ":new";
          v = "vsplit";
        };
        "C-k" = "page_cursor_half_up";
        "C-j" = "page_cursor_half_down";
        "K" = "hover";
        "ret" = "goto_word";
      };
      keys.select = {
        "C-w" = "no_op";
        "C-k" = "page_cursor_half_up";
        "C-j" = "page_cursor_half_down";
      };
    };

    languages = {
      language-server = {
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
        };
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
        luals = {
          command = "${pkgs.lua-language-server}/bin/lua-language-server";
        };

        pyright = {
          command = "${pkgs.pyright}/bin/pyright-langserver";
          args = [ "--stdio" ];
          config = {
            python.analysis = {
              autoSearchPaths = true;
              useLibraryCodeForTypes = true;
              diagnosticMode = "openFilesOnly";
            };
          };
        };

        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };

        clangd = {
          command = "${pkgs.clang-tools}/bin/clangd";
          args = [
            "--background-index"
            "--offset-encoding=utf-8"
            "--query-driver=/Users/scie/.platformio/packages/toolchain-xtensa-esp32/**"
            "--query-driver=/Users/scie/.platformio/packages/framework-arduinoststm32/**"
          ];
        };

        tailwindcss = {
          command = "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
          args = [ "--stdio" ];
        };

        zls.command = "${pkgs.zls}/bin/zls";
        gopls.command = "${pkgs.gopls}/bin/gopls";

        tinymist = {
          command = "${pkgs.tinymist}/bin/tinymist";
          config.tinymist.formatterMode = "typstyle";
        };

        rust-analyzer = {
          command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
          config."rust-analyzer" = {
            check.command = "clippy";
            diagnostics.enable = true;
          };
        };

        gdscript = {
          command = "${pkgs.netcat}/bin/nc";
          args = [
            "127.0.0.1"
            "6005"
          ];
        };

        # csharp-ls = {
        # command = "${pkgs.csharp-ls}/bin/csharp-ls";
        # config.AutomaticWorkspaceInit = true;
        # };

        asm-lsp.command = "${pkgs.asm-lsp}/bin/asm-lsp";

        codebook = {
          command = "${pkgs.codebook}/bin/codebook-lsp";
          args = [ "serve" ];
        };

        json = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
          args = [ "--stdio" ];
          config.provideFormatter = true;
        };

        eslint = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server";
          args = [ "--stdio" ];
        };

        css = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
          args = [ "--stdio" ];
        };

        html = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
          args = [ "--stdio" ];
          config = {
            provideFormatter = true;
            embeddedLanguages = {
              css = true;
              javascript = true;
            };
            configurationSection = [
              "html"
              "css"
              "javascript"
            ];
          };
        };

        fish = {
          command = "${pkgs.fish-lsp}/bin/fish-lsp";
          args = [ "start" ];
        };

        astro = {
          command = "${pkgs.astro-language-server}/bin/astro-ls";
          args = [ "--stdio" ];
          config.typescript.tsdk = "./node_modules/typescript/lib";
        };
      };

      language = [
        {
          name = "nix";
          scope = "source.nix";
          file-types = [ "nix" ];
          language-servers = [
            "nixd"
            "nil"
            "codebook"
          ];
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          auto-format = true;
          roots = wRoots [ ];
        }
        {
          name = "lua";
          scope = "source.lua";
          file-types = [ "lua" ];
          language-servers = [
            "luals"
            "codebook"
          ];
          roots = wRoots [
            ".luarc.json"
            ".luarc.jsonc"
          ];
        }
        {
          name = "python";
          scope = "source.python";
          file-types = [
            "py"
            "pyi"
          ];
          language-servers = [
            "pyright"
            "ruff"
            "codebook"
          ];
          roots = wRoots [
            "pyproject.toml"
            "setup.py"
            "setup.cfg"
            "requirements.txt"
            "Pipfile"
            "pyrightconfig.json"
          ];
        }
        {
          name = "c";
          scope = "source.c";
          file-types = [
            "c"
            "h"
            "arduino"
          ];
          language-servers = [
            "clangd"
            "codebook"
          ];
          roots = wRoots [
            ".clangd"
            ".clang-tidy"
            ".clang-format"
            "compile_commands.json"
            "compile_flags.txt"
            "configure.ac"
          ];
        }
        {
          name = "cpp";
          scope = "source.cpp";
          file-types = [
            "cc"
            "hh"
            "cxx"
            "hpp"
            "cpp"
            "hxx"
            "proto"
          ];
          language-servers = [
            "clangd"
            "codebook"
          ];
          roots = wRoots [
            ".clangd"
            ".clang-tidy"
            ".clang-format"
            "compile_commands.json"
            "compile_flags.txt"
            "configure.ac"
          ];
        }
        {
          name = "zig";
          scope = "source.zig";
          file-types = [ "zig" ];
          language-servers = [
            "zls"
            "codebook"
          ];
          roots = wRoots [
            "zls.json"
            "build.zig"
          ];
        }
        {
          name = "go";
          scope = "source.go";
          file-types = [
            "go"
            "gomod"
            "gowork"
            "gotmpl"
          ];
          language-servers = [
            "gopls"
            "codebook"
          ];
          roots = wRoots [
            "go.work"
            "go.mod"
          ];
        }
        {
          name = "typst";
          scope = "source.typst";
          file-types = [ "typ" ];
          language-servers = [
            "tinymist"
            "codebook"
          ];
          roots = wRoots [ ];
          text-width = 80;
          soft-wrap = {
            enable = true;
            max-indent-retain = 40;
            wrap-at-text-width = true;
            wrap-indicator = " ";
          };
        }
        {
          name = "markdown";
          language-servers = [ "codebook" ];
          roots = wRoots [ ];
          text-width = 80;
          soft-wrap = {
            enable = true;
            max-indent-retain = 40;
            wrap-at-text-width = true;
            wrap-indicator = " ";
          };
        }
        {
          name = "rust";
          scope = "source.rust";
          file-types = [ "rs" ];
          language-servers = [
            "rust-analyzer"
            "codebook"
          ];
          roots = wRoots [
            "Cargo.toml"
            "Cargo.lock"
          ];
        }
        {
          name = "gdscript";
          scope = "source.gdscript";
          file-types = [ "gd" ];
          language-servers = [ "gdscript" ];
          roots = wRoots [
            "project.godot"
          ];
        }
        {
          name = "c-sharp";
          scope = "source.cs";
          file-types = [ "cs" ];
          language-servers = [ "csharp-ls" ];
          roots = wRoots [ ];
        }
        {
          name = "asm";
          scope = "source.asm";
          file-types = [
            "s"
            "S"
            "asm"
          ];
          language-servers = [ "asm-lsp" ];
          roots = wRoots [
            ".asm-lsp.toml"
          ];
        }
        {
          name = "json";
          scope = "source.json";
          file-types = [
            "json"
            "jsonc"
          ];
          language-servers = [
            "json"
            "codebook"
          ];
          roots = wRoots [ ];
        }
        {
          name = "javascript";
          scope = "source.js";
          file-types = [
            "js"
            "jsx"
            "mjs"
            "cjs"
          ];
          language-servers = [
            "eslint"
            "tailwindcss"
            "codebook"
          ];
          roots = wRoots [
            "package.json"
          ];
        }
        {
          name = "typescript";
          scope = "source.ts";
          file-types = [
            "ts"
            "tsx"
            "mts"
            "cts"
          ];
          language-servers = [
            "eslint"
            "tailwindcss"
            "codebook"
          ];
          roots = wRoots [
            "package.json"
            "tsconfig.json"
          ];
        }
        {
          name = "html";
          scope = "source.html";
          file-types = [ "html" ];
          language-servers = [
            "html"
            "tailwindcss"
            "codebook"
          ];
          roots = wRoots [
            "package.json"
          ];
        }
        {
          name = "css";
          scope = "source.css";
          file-types = [
            "css"
            "scss"
            "less"
          ];
          language-servers = [
            "css"
            "tailwindcss"
            "codebook"
          ];
          roots = wRoots [
            "package.json"
          ];
        }
        {
          name = "astro";
          scope = "source.astro";
          file-types = [ "astro" ];
          language-servers = [
            "astro"
            "eslint"
            "tailwindcss"
          ];
          roots = wRoots [
            "package.json"
            "tsconfig.json"
            "jsconfig.json"
          ];
        }
        {
          name = "fish";
          scope = "source.fish";
          file-types = [ "fish" ];
          language-servers = [ "fish" ];
          roots = wRoots [
            "config.fish"
          ];
        }
      ];
    };

    themes.grace_rose_pine = {
      inherits = "rose_pine_moon";

      "ui.statusline" = {
        fg = "text";
        bg = "surface";
      };
      "ui.statusline.inactive" = {
        fg = "muted";
        bg = "base";
      };
      "ui.statusline.normal" = {
        fg = "base";
        bg = "pine";
        modifiers = [ "bold" ];
      };
      "ui.statusline.insert" = {
        fg = "base";
        bg = "pine";
        modifiers = [ "bold" ];
      };
      "ui.statusline.select" = {
        fg = "base";
        bg = "pine";
        modifiers = [ "bold" ];
      };
      "ui.statusline.separator" = {
        fg = "pine";
        bg = "surface";
      };
      "ui.bufferline" = {
        fg = "subtle";
        bg = "base";
      };
      "ui.bufferline.active" = {
        fg = "base";
        bg = "rose";
        modifiers = [ "bold" ];
      };
      "ui.bufferline.background" = {
        bg = "base";
      };
    };

  };

}

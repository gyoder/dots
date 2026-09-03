{
  config,
  lib,
  pkgs,
  ...
}:

let
  dots = toString ./..;
in
{
  home.packages = with pkgs; [
    pfetch-rs
    sesh
    ripgrep
    dust
    tree
    btop
    curl
    fd
    uutils-coreutils
    wget
    jq
    yq
    yj
    most
    asciinema
    bash
    openssh
    openssl
  ];

  xdg.configFile."fish/themes/rose_pine.theme".source =
    config.lib.file.mkOutOfStoreSymlink "${dots}/fish/rose_pine.theme";

  programs.fish = {
    enable = true;

    shellAliases = {
      setupidf = "source /opt/esp/esp-idf/export.fish";
      pysource = "source .venv/bin/activate.fish";
      tcl = "clear && clear";
      tclear = "clear && clear";
    };

    functions = {
      ask = {
        description = "Ask for input and respond with input";
        body = ''
          read -s -P "Enter Input: " response
          echo $response
        '';
      };

      loadenv = ''
        argparse h/help print printb U/unload -- $argv
        or return 1

        if set -q _flag_help
            echo "Usage: loadenv [OPTIONS] [FILE]"
            echo ""
            echo "Export keys and values from a dotenv file."
            echo ""
            echo "Options:"
            echo "  --help, -h      Show this help message"
            echo "  --print         Print env keys (export preview)"
            echo "  --printb        Print keys with surrounding brackets"
            echo "  --unload, -U    Unexport all keys defined in the dotenv file"
            echo ""
            echo "Arguments:"
            echo "  FILE            Path to dotenv file (default: .env)"
            return 0
        end

        if test (count $argv) -gt 1
            echo "Too many arguments. Only one argument is allowed. Use --help for more information."
            return 1
        end

        set -l dotenv_file ".env"
        if test (count $argv) -eq 1
            set dotenv_file $argv[1]
        end

        if not test -f $dotenv_file
            echo "Error: File '$dotenv_file' not found in the current directory."
            return 1
        end

        set -l mode load
        if set -q _flag_print
            set mode print
        else if set -q _flag_printb
            set mode printb
        else if set -q _flag_unload
            set mode unload
        end

        set lineNumber 0

        for line in (cat $dotenv_file)
            set lineNumber (math $lineNumber + 1)

            if string match -qr '^\s*$|^\s*#' $line
                continue
            end

            if not string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' $line
                echo "Error: invalid declaration (line $lineNumber): $line"
                return 1
            end

            set -l key (string split -m 1 '=' $line)[1]
            set -l after_equals_sign (string split -m 1 '=' $line)[2]

            set -l value
            set -l double_quoted_value_regex '^"(.*)"\s*(?:#.*)*$'
            set -l single_quoted_value_regex '^\'(.*)\'\s*(?:#.*)*$'
            set -l plain_value_regex '^([^\'"\s]*)\s*(?:#.*)*$'
            if string match -qgr $double_quoted_value_regex $after_equals_sign
                set value (string match -gr $double_quoted_value_regex $after_equals_sign)
            else if string match -qgr $single_quoted_value_regex $after_equals_sign
                set value (string match -gr $single_quoted_value_regex $after_equals_sign)
            else if string match -qgr $plain_value_regex $after_equals_sign
                set value (string match -gr $plain_value_regex $after_equals_sign)
            else
                echo "Error: invalid value (line $lineNumber): $line"
                return 1
            end

            switch $mode
                case print
                    echo "$key=$value"
                case printb
                    echo "[$key=$value]"
                case load
                    set -gx $key $value
                case unload
                    set -e $key
            end
        end
      '';

      # Broken :/
      nix = {
        wraps = "nix";
        body = ''
          if test (count $argv) -gt 0; and test "$argv[1]" = shell
              set -lx STARSHIP_NIX_SHELL shell
          end

          command nix $argv
        '';
      };
    };

    interactiveShellInit = ''
      set -g fish_greeting ""
      fish_vi_key_bindings
      fish_config theme choose rose_pine
      pfetch
    '';
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    extraPackages = [
      pkgs.jj-starship
    ];

    settings = {
      format = lib.concatStrings [
        "$hostname"
        "$username"
        "$directory"
        "$git_branch"
        "$git_status"
        "\${custom.jj}"
        "\${custom.git_status}"
        "$fill"
        "\${env_var.NIX_SHELL}"
        "$c"
        "$elixir"
        "$elm"
        "$golang"
        "$haskell"
        "$java"
        "$julia"
        "$nodejs"
        "$nim"
        "$rust"
        "$scala"
        "$conda"
        "$python"
        "$time"
        "\n"
        "[❯](fg:iris) "
      ];

      palette = "rose-pine";

      palettes = {
        rose-pine = {
          overlay = "#26233a";
          love = "#eb6f92";
          gold = "#f6c177";
          rose = "#ebbcba";
          pine = "#31748f";
          foam = "#9ccfd8";
          iris = "#c4a7e7";
        };
      };

      directory = {
        format = "[](fg:overlay)[ $path ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:pine";
        truncation_length = 3;
        truncation_symbol = "…/";

        substitutions = {
          Documents = "󰈙";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      fill = {
        style = "fg:overlay";
        symbol = " ";
      };

      git_branch = {
        disabled = true;
        format = "[](fg:overlay)[ $symbol $branch ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:foam";
        symbol = "";
      };

      git_status = {
        disabled = true;
        style = "bg:overlay fg:love";
        format = "[](fg:overlay)([$all_status$ahead_behind]($style))[](fg:overlay) ";

        up_to_date = "[ ✓ ](bg:overlay fg:iris)";

        untracked = ''[?\($count\)](bg:overlay fg:gold)'';

        stashed = ''[\$](bg:overlay fg:iris)'';

        modified = ''[!\($count\)](bg:overlay fg:gold)'';

        renamed = ''[»\($count\)](bg:overlay fg:iris)'';

        deleted = ''[✘\($count\)](style)'';

        staged = ''[++\($count\)](bg:overlay fg:gold)'';

        ahead = ''[⇡\(''${count}\)](bg:overlay fg:foam)'';

        diverged = ''⇕[\[](bg:overlay fg:iris)[⇡\(''${ahead_count}\)](bg:overlay fg:foam)[⇣\(''${behind_count}\)](bg:overlay fg:rose)[\]](bg:overlay fg:iris)'';

        behind = ''[⇣\(''${count}\)](bg:overlay fg:rose)'';
      };

      custom = {
        jj = {
          command = ''
            jj-starship --git-symbol "" --no-git-status | sed "s/\x1b\[0m//g"
          '';

          when = "jj-starship detect";

          shell = [
            "sh"
          ];

          format = "[](fg:overlay)[[ $output ](bg:overlay)]($style)[](fg:overlay) ";

          style = "bg:overlay fg:rose";

          unsafe_no_escape = true;
        };

        git_status = {
          command = ''
            git status --porcelain | awk '
              /^[MARC ][MD]/ || /^[MARC][MARC ]/ { modified++ }
              /^\?\?/ { untracked++ }
              /^[D ]D/ || /^D/ { deleted++ }
              END {
                if (modified + untracked + deleted == 0) {
                  printf "\033[38;2;196;167;231m✓"
                } else {
                  if (modified)  printf "\033[38;2;246;193;119m%d ", modified
                  if (untracked) printf "\033[38;2;246;193;119m%d ", untracked
                  if (deleted)   printf "\033[38;2;235;111;146m󰆴%d ", deleted
                }
              }
            '

            unpushed=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')

            if [ -n "$unpushed" ] && [ "$unpushed" -gt 0 ]; then
              printf "\033[38;2;137;220;235m⇡%d " "$unpushed"
            fi
          '';

          when = "git rev-parse --is-inside-work-tree 2>/dev/null && ! jj root 2>/dev/null";

          shell = [
            "sh"
          ];

          format = "[](fg:overlay)[[ $output ](bg:overlay)]($style)[](fg:overlay) ";

          style = "bg:overlay fg:love";

          unsafe_no_escape = true;
        };
      };

      time = {
        disabled = false;
        format = " [](fg:overlay)[ $time 󰴈 ]($style)[](fg:overlay)";
        style = "bg:overlay fg:rose";
        time_format = "%I:%M%P";
        use_12hr = true;
      };

      hostname = {
        disabled = false;
        ssh_only = false;
        trim_at = "";
        format = "[](fg:overlay)[ 󰠧 $hostname$ssh_symbol ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:rose";
        ssh_symbol = " ";
      };

      username = {
        disabled = false;
        format = "[](fg:overlay)[ 󰧱 $user ]($style)[](fg:overlay) ";
        show_always = true;
        style_root = "bg:overlay fg:iris";
        style_user = "bg:overlay fg:iris";
      };

      env_var.NIX_SHELL = {
        variable = "STARSHIP_NIX_SHELL";
        symbol = " ";
        format = "[](fg:overlay)[ $symbol$env_value ]($style)[](fg:overlay) ";
        style = "bg:overlay fg:foam";
      };

      # Languages

      c = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      elixir = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      elm = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      golang = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      haskell = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      java = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      julia = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      nodejs = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = "󰎙 ";
      };

      nim = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = "󰆥 ";
      };

      rust = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      scala = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      python = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$version ]($style)[](fg:overlay)";
        disabled = false;
        symbol = " ";
      };

      conda = {
        style = "bg:overlay fg:pine";
        format = " [](fg:overlay)[ $symbol$environment ]($style)[](fg:overlay)";
        disabled = false;
        symbol = "🅒 ";
      };
    };
  };

}

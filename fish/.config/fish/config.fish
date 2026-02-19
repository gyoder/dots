set host (hostname)

if string match -q "*turing*" "$host"
    set -x PATH /Users/scie/.local/nvim-macos-arm64/bin \
      /opt/homebrew/Cellar/universal-ctags/HEAD-43ca055/bin \
      /Users/scie/.local/xonsh-env/xbin \
      /Users/scie/.local/xonsh-env/xbin \
      /opt/homebrew/opt/icu4c@76/sbin \
      /opt/homebrew/opt/icu4c@76/bin \
      /opt/homebrew/opt/llvm/bin \
      /Users/scie/.dotnet/tools \
      /Users/scie/.local/bin \
      /Users/scie/Library/Python/3.9/bin \
      /opt/local/var/macports/sources/rsync.macports.org/macports/release/tarballs/ports/emulators \
      /opt/homebrew/bin/iodine \
      /opt/homebrew/bin \
      /opt/homebrew/opt/zig@0.14/bin \
      /Users/scie/.platformio/penv/bin/ \
      /Users/scie/.cargo/bin \
      /Users/scie/.local/xonsh-env/xbin \
      /Users/scie/go/bin \
      /usr/bin \
      /usr/local/bin \
      /usr/sbin \
      /usr/local/sbin \
      /bin \
      /sbin
else if test "$host" = "lovelace"
    set -x PATH /home/scie/.local/bin \
      /home/linuxbrew/.linuxbrew/bin \
      /home/linuxbrew/.linuxbrew/sbin \
      /home/scie/.nvm/versions/node/v22.15.0/bin \
      /home/scie/.cargo/bin \
      /usr/local/sbin \
      /usr/local/bin \
      /usr/sbin \
      /usr/bin \
      /sbin \
      /bin \
      /usr/games \
      /usr/local/games \
      /snap/bin
else if test "$host" = "lee"
  fish_add_path ~/.local/bin
end

if status is-interactive
  set -g fish_greeting ""
  pfetch

  fish_config theme choose "Rosé Pine"
  starship init fish | source
  zoxide init fish | source
end

alias setupidf "source /opt/esp/esp-idf/export.fish"

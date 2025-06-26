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
      /Users/scie/.platformio/penv/bin/ \
      /Users/scie/.cargo/bin \
      /Users/scie/.local/xonsh-env/xbin \
      /usr/bin \
      /usr/sbin \
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
end

if status is-interactive
  fish_config theme choose "Rosé Pine"
  zoxide init fish | source
end

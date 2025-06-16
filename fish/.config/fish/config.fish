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
  /usr/bin \
  /opt/homebrew/bin/iodine \
  /opt/homebrew/bin \
  /Users/scie/.platformio/penv/bin/ \
  /Users/scie/.cargo/bin \
  /Users/scie/.local/xonsh-env/xbin \
  /usr/bin \
  /bin
if status is-interactive
  function source_env
    if not test -f .env
      echo "No .env file found in current directory"
      return 1
    end

    for line in (cat .env)
      set line (string trim -- $line)
      # Skip empty lines and comments
      if test -z "$line" -o (string sub --start 1 --length 1 "$line") = "#"
        continue
      end
      # Check if line contains =
      if string match -q "*=*" "$line"
        set parts (string split -m1 '=' "$line")
        set var_name $parts[1]
        set var_value $parts[2]
        # Remove surrounding quotes if present
        set var_value (string trim --chars='"' "$var_value")
        set var_value (string trim --chars="'" "$var_value")
        set -x $var_name $var_value
      end
    end
  end
end

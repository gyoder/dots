{ pkgs, ... }:

let
  build = pkgs.writeText "nixos-target-build" ''
    set -eu
    export PATH=/run/current-system/sw/bin:/usr/bin:/bin
    drv="$1"
    root="/nix/var/nix/gcroots/$2.drv"
    finish() {
      status=$?
      trap - EXIT
      rm -f "$root"
      if [ "$status" -ne 0 ]; then
        /run/current-system/bin/notify-nixos-switch failed "$status" || true
      fi
      exit "$status"
    }
    trap finish EXIT
    ln -s "$drv" "$root"
    system=$(nix-store --realise "$drv")
    nix-env --profile /nix/var/nix/profiles/system --set "$system"
    "$system/bin/switch-to-configuration" switch
  '';

  deploy = pkgs.writeShellScript "nixos-target" ''
    set -eu
    export NIX_HOST="$1"
    target="grace@$NIX_HOST.i.gae.moe"
    tmp=$(${pkgs.coreutils}/bin/mktemp -d)
    trap '${pkgs.coreutils}/bin/rm -f "$tmp/system.drv"; ${pkgs.coreutils}/bin/rmdir "$tmp"' EXIT
    ${pkgs.nix}/bin/nix-instantiate ./system.nix -A system \
      --add-root "$tmp/system.drv" --indirect >/dev/null
    drv=$(${pkgs.coreutils}/bin/readlink -f "$tmp/system.drv")
    ${pkgs.nix}/bin/nix --extra-experimental-features nix-command \
      copy --to "ssh://$target" "$drv" ${build}
    unit="nixos-target-$(${pkgs.coreutils}/bin/date +%s)-''${tmp##*/}"

    if [ "$2" = listen ]; then
      ${pkgs.openssh}/bin/ssh "$target" "sudo -n /bin/sh -c '
        journalctl --unit=$unit --follow --no-tail &
        logger=\$!
        systemd-run --unit=$unit --collect --wait /bin/sh ${build} $drv $unit
        status=\$?
        kill \$logger
        wait \$logger 2>/dev/null || true
        exit \$status
      '"
    else
      ${pkgs.openssh}/bin/ssh "$target" \
        "sudo -n systemd-run --unit=$unit --collect --no-block /bin/sh ${build} $drv $unit"
      printf 'Rebuild queued on %s. Follow logs with:\n  ssh %s sudo journalctl -fu %s\n' \
        "$NIX_HOST" "$target" "$unit"
    fi
  '';
in
{
  programs.fish.functions.nixos-target = {
    description = "Build and deploy a local NixOS configuration on a remote host";
    body = ''
      argparse l/listen -- $argv
      or return 2
      if test (count $argv) -ne 1
        echo "Usage: nixos-target [-l|--listen] HOST" >&2
        return 2
      end

      if not string match -qr '^[a-zA-Z0-9][a-zA-Z0-9-]*$' -- $argv[1]
        echo "Invalid host name: $argv[1]" >&2
        return 2
      end

      set -l mode background
      if set -q _flag_listen
        set mode listen
      end
      ${deploy} $argv[1] $mode
    '';
  };
}

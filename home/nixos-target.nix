{ pkgs, ... }:

let
  runner = pkgs.writeText "nixos-target-runner" ''
    set -eu
    export PATH=/run/current-system/sw/bin:/usr/bin:/bin
    drv="$1"
    unit="$2"
    host="$3"
    export NIX_HOST="$host"
    export _NIXOS_REBUILD_REEXEC=1
    root="/nix/var/nix/gcroots/$unit.drv"
    finish() {
      status=$?
      trap - EXIT
      rm -f "$root"
      if [ "$status" -ne 0 ]; then
        /run/current-system/bin/notify-nixos-switch failed "$status" "$host" || true
      fi
      exit "$status"
    }
    trap finish EXIT
    ln -s "$drv" "$root"
    system=$(nix-store --realise "$drv")
    if [ "$host" = dijkstra ]; then
      nixos-rebuild switch --store-path "$system"
    else
      sudo -n -H -u grace -- env \
        NIX_SSHOPTS='-o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=2' \
        nixos-rebuild switch --store-path "$system" \
        --target-host "grace@$host.i.gae.moe" --sudo
    fi
  '';

  deploy = pkgs.writeShellScript "nixos-target" ''
    set -eu
    export NIX_HOST="$1"
    builder="grace@dijkstra.i.gae.moe"
    tmp=$(${pkgs.coreutils}/bin/mktemp -d)
    trap '${pkgs.coreutils}/bin/rm -f "$tmp/system.drv"; ${pkgs.coreutils}/bin/rmdir "$tmp"' EXIT
    ${pkgs.nix}/bin/nix-instantiate ./system.nix -A system \
      --add-root "$tmp/system.drv" --indirect >/dev/null
    drv=$(${pkgs.coreutils}/bin/readlink -f "$tmp/system.drv")
    ${pkgs.nix}/bin/nix --extra-experimental-features nix-command \
      copy --to "ssh://$builder" "$drv" ${runner}
    unit="nixos-target-$NIX_HOST-$(${pkgs.coreutils}/bin/date +%s)-''${tmp##*/}"

    if [ "''${2-}" = listen ]; then
      exec ${pkgs.openssh}/bin/ssh "$builder" \
        "sudo -n systemd-run --unit=$unit --collect --wait /bin/sh ${runner} $drv $unit $NIX_HOST"
    fi
    ${pkgs.openssh}/bin/ssh "$builder" \
      "sudo -n systemd-run --unit=$unit --collect --no-block /bin/sh ${runner} $drv $unit $NIX_HOST"
    printf 'Rebuild queued on dijkstra for %s. Follow logs with:\n  ssh %s sudo journalctl -fu %s\n' \
      "$NIX_HOST" "$builder" "$unit"
  '';
in
{
  programs.fish.functions.nixos-target = {
    description = "Build a local NixOS configuration on dijkstra and deploy it to a host";
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

      if set -q _flag_listen
        ${deploy} $argv[1] listen
      else
        ${deploy} $argv[1]
      end
    '';
  };
}

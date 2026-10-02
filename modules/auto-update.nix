{ pkgs, ... }:

{
  system.autoUpgrade = {
    enable = true;
    dates = "minutely";
    allowReboot = true;
    upgrade = false;
  };

  systemd.services.nixos-upgrade = {
    path = [ pkgs.git ];
    serviceConfig = {
      WorkingDirectory = "/etc/nixos";
      StateDirectory = "nixos-repo-update";
      ExecCondition = pkgs.writeShellScript "check-nixos-repo" ''
        set -euo pipefail
        git fetch || exit 255
        test "$(cat "$STATE_DIRECTORY/applied" 2>/dev/null || true)" != "$(git rev-parse '@{upstream}')"
      '';
    };

    preStart = "git pull --ff-only";
    postStart = ''git rev-parse HEAD > "$STATE_DIRECTORY/applied"'';
  };
}

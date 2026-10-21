{
  config,
  lib,
  pkgs,
  ...
}:

let
  notify = pkgs.writeShellScript "notify-nixos-switch" ''
    credentials=/etc/secrets/ntfy-nixos-switch.curl
    if [ ! -r "$credentials" ]; then
      exit 0
    fi

    if [ "''${1:-}" = failed ]; then
      outcome="rebuild failed"
      message="NixOS rebuild failed (exit status ''${2:-unknown})"
      host="''${3:-${lib.escapeShellArg config.networking.hostName}}"
    else
      outcome="switch succeeded"
      message="Successfully switched to $(${pkgs.coreutils}/bin/readlink -f /run/current-system)"
      host=${lib.escapeShellArg config.networking.hostName}
    fi

    printf '%s: %s\n' "$host" "$message" |
      ${pkgs.curl}/bin/curl \
        --config "$credentials" \
        --fail --silent --show-error \
        --connect-timeout 3 --max-time 10 \
        --header "Title: $host: NixOS $outcome" \
        --data-binary @- \
        --output /dev/null \
        https://ntfy.gae.moe/nixos
  '';

  switch = pkgs.writeShellScript "switch-to-configuration-notify" ''
    "''${0%/*}/switch-to-configuration-unnotified" "$@"
    status=$?
    if [ "$status" -eq 0 ] && [ "''${1:-}" = switch ]; then
      "''${0%/*}/notify-nixos-switch" || true
    fi
    exit "$status"
  '';
in
{
  config = lib.mkIf config.system.switch.enable {
    system.activatableSystemBuilderCommands = lib.mkAfter ''
      mv "$out/bin/switch-to-configuration" "$out/bin/switch-to-configuration-unnotified"
      ln -s ${notify} "$out/bin/notify-nixos-switch"
      ln -s ${switch} "$out/bin/switch-to-configuration"
    '';
  };
}

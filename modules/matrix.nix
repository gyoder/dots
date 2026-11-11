{ config, pkgs, ... }:

let
  ooye = pkgs.callPackage ../pkgs/ooye.nix { };
in
{
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  services.matrix-continuwuity = {
    enable = true;
    package = pkgs.callPackage ../pkgs/continuwuity-legacy.nix { };
    settings.global = {
      server_name = "gae.moe";
      address = [ "0.0.0.0" ];
      port = [ 6167 ];
      allow_registration = false;
      allow_federation = true;
      well_known.client = "https://matrix.gae.moe";
      oauth.compatibility_mode = "exclusive";
      oauth.oidc = {
        discovery_url = "https://auth.gae.moe";
        client_id = "continuwuity";
        client_secret_file = "/run/credentials/continuwuity.service/oidc-client-secret";
        additional_scopes = [ "profile" ];
      };
    };
  };

  sops.secrets.continuwuity-oidc-client-secret = {
    sopsFile = ../secrets/dijkstra/continuwuity-oidc-client-secret.json;
    format = "binary";
    restartUnits = [ "continuwuity.service" ];
  };

  systemd.services.continuwuity.serviceConfig.LoadCredential = [
    "oidc-client-secret:${config.sops.secrets.continuwuity-oidc-client-secret.path}"
  ];

  services.mautrix-discord = {
    enable = true;
    dataDir = "/var/lib/mautrix-discord";
    settings = {
      homeserver = {
        address = "https://matrix.gae.moe";
        domain = "gae.moe";
      };
      appservice = {
        address = "http://127.0.0.1:29334";
        hostname = "127.0.0.1";
      };
      bridge.permissions."@grace:gae.moe" = "admin";
    };
  };

  systemd.services.mautrix-discord = {
    wants = [ "continuwuity.service" ];
    after = [ "continuwuity.service" ];
  };

  users.groups.ooye = { };
  users.users.ooye = {
    isSystemUser = true;
    group = "ooye";
    home = "/var/lib/ooye";
  };

  systemd.tmpfiles.rules = [ "d /var/lib/ooye 0700 ooye ooye -" ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "ooye-configure" ''
      set -eu
      umask 077
      cd /var/lib/ooye
      ${ooye}/bin/ooye-setup
      touch .configured
    '')
  ];

  systemd.services.ooye = {
    description = "Out Of Your Element Matrix-Discord bridge";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "continuwuity.service"
    ];
    unitConfig.ConditionPathExists = "/var/lib/ooye/.configured";
    serviceConfig = {
      User = "ooye";
      Group = "ooye";
      WorkingDirectory = "/var/lib/ooye";
      StateDirectory = "ooye";
      StateDirectoryMode = "0700";
      ExecStart = "${ooye}/bin/ooye";
      Restart = "on-failure";
      RestartSec = 10;
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  systemd.services.backup-matrix = {
    description = "Back up Matrix and Discord bridge state with services stopped";
    unitConfig.RequiresMountsFor = [ "/mnt/backup" ];
    path = [
      pkgs.rsync
      pkgs.util-linux
      pkgs.coreutils
      pkgs.systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      set -eu
      mountpoint -q /mnt/backup
      install -d -m 0700 /mnt/backup/matrix
      active=""
      for unit in ooye.service mautrix-discord.service continuwuity.service; do
        if systemctl is-active --quiet "$unit"; then
          active="$active $unit"
        fi
      done
      trap 'if [ -n "$active" ]; then systemctl start $active; fi' EXIT
      systemctl stop ooye.service mautrix-discord.service continuwuity.service
      if [ -d /var/lib/continuwuity ]; then
        rsync -a --delete /var/lib/continuwuity/ /mnt/backup/matrix/continuwuity/
      fi
      rsync -a --delete /var/lib/ooye/ /mnt/backup/matrix/ooye/
      if [ -d /var/lib/mautrix-discord ]; then
        rsync -a --delete /var/lib/mautrix-discord/ /mnt/backup/matrix/mautrix-discord/
      fi
    '';
  };

  systemd.timers.backup-matrix = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}

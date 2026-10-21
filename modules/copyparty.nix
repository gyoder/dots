{ lib, pkgs, ... }:

let
  host = import ../hosts.nix;
  tailnet = import ../tailnet.nix;
  configuration = pkgs.writeText "copyparty.conf" ''
    [global]
      i: 0.0.0.0
      p: 8080
      rproxy: 1
      xff-src: ${tailnet.knuth}
      idp-h-usr: Remote-User
      auth-ord: idp,pw
      idp-login: https://auth.gae.moe
      hist: /mnt/data/copyparty/history
      e2dsa
      no-reload
      no-robots
      chmod-f: 660
      chmod-d: 2770

    [/]
      /mnt/data/share
      accs:
        rwmd: ${host.user}
      flags:
        scan: 300
  '';
in
{
  imports = [ ./share.nix ];

  users.users.copyparty = {
    isSystemUser = true;
    group = "share";
    home = "/mnt/data/copyparty";
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data/copyparty 0700 copyparty share -"
  ];

  environment.etc."copyparty/config.conf".source = configuration;
  environment.systemPackages = [ pkgs.copyparty ];

  systemd.services.copyparty = {
    description = "Copyparty file server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig.RequiresMountsFor = [ "/mnt/data" ];
    environment = {
      PYTHONUNBUFFERED = "1";
      XDG_CONFIG_HOME = "/mnt/data/copyparty";
    };
    serviceConfig = {
      User = "copyparty";
      Group = "share";
      WorkingDirectory = "/mnt/data/copyparty";
      ExecStart = "${lib.getExe pkgs.copyparty} -c ${configuration} -c %d/accounts.conf";
      LoadCredential = [ "accounts.conf:/etc/secrets/copyparty.conf" ];
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0007";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/mnt/data/share"
        "/mnt/data/copyparty"
      ];
    };
  };
}

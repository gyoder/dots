{
  host,
  pkgs,
  ...
}:

let
  root = "/mnt/backup";
  timemachine = "${root}/timemachine";
in
{
  users.users.${host.user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzErojBe08D6vMxI+LJXOx7bM+RJF7ZFrCopagpYNm6 root@knuth"
  ];

  systemd.services.backup-directories = {
    description = "Prepare the Time Machine directory on the mounted backup disk";
    requiredBy = [
      "samba-smbd.service"
    ];
    before = [
      "samba-smbd.service"
    ];
    unitConfig.RequiresMountsFor = [ root ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${host.user} -g users ${timemachine}
    '';
  };

  services.samba.settings = {
    global = {
      "vfs objects" = "catia fruit streams_xattr";
      "fruit:metadata" = "stream";
      "fruit:model" = "MacSamba";
    };
    timemachine = {
      path = timemachine;
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "valid users" = host.user;
      "force user" = host.user;
      "create mask" = "0600";
      "directory mask" = "0700";
      "fruit:time machine" = "yes";
      "hosts allow" = "100.64.0.0/10 fd7a:115c:a1e0::/48 127.0.0.1 ::1";
      "hosts deny" = "ALL";
    };
  };
  systemd.services.samba-smbd = {
    unitConfig.RequiresMountsFor = [ root ];
  };
}

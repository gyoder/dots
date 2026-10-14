{ config, pkgs, ... }:

let
  host = import ../hosts.nix;
  root = "/mnt/backup";
  nfs = "${root}/nfs";
  timemachine = "${root}/timemachine";
  uid = toString config.users.users.${host.user}.uid;
  gid = toString config.ids.gids.users;
  exportOptions = [
    "rw"
    "sync"
    "fsid=0"
    "all_squash"
    "anonuid=${uid}"
    "anongid=${gid}"
    "no_subtree_check"
    "insecure"
  ];
in
{
  users.users.${host.user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzErojBe08D6vMxI+LJXOx7bM+RJF7ZFrCopagpYNm6 root@knuth"
  ];

  services.nfs.server = {
    enable = true;
    exports.${nfs} = {
      "100.64.0.0/10" = exportOptions;
      "fd7a:115c:a1e0::/48" = exportOptions;
    };
  };
  services.nfs.settings.nfsd = {
    vers3 = false;
    vers4 = true;
    udp = false;
  };
  systemd.services.nfs-server = {
    unitConfig.RequiresMountsFor = [ root ];
  };

  systemd.services.backup-directories = {
    description = "Prepare backup shares on the mounted backup disk";
    requiredBy = [
      "nfs-server.service"
      "nfs-mountd.service"
      "samba-smbd.service"
    ];
    before = [
      "nfs-server.service"
      "nfs-mountd.service"
      "samba-smbd.service"
    ];
    unitConfig.RequiresMountsFor = [ root ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${host.user} -g users ${nfs} ${timemachine}
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

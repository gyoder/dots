{ config, ... }:

let
  host = import ../hosts.nix;
  exportOptions = [
    "rw"
    "sync"
    "all_squash"
    "anonuid=${toString config.users.users.${host.user}.uid}"
    "anongid=${toString config.users.groups.share.gid}"
    "no_subtree_check"
    "insecure"
  ];
in
{
  imports = [ ./share.nix ];

  services.nfs.server = {
    enable = true;
    exports."/mnt/data/share" = {
      "100.64.0.0/10" = exportOptions;
      "fd7a:115c:a1e0::/48" = exportOptions;
    };
  };

  systemd.services.nfs-server.unitConfig.RequiresMountsFor = [ "/mnt/data" ];
  systemd.services.nfs-mountd.unitConfig.RequiresMountsFor = [ "/mnt/data" ];
}

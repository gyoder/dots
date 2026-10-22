{ pkgs, ... }:

let
  host = import ../hosts.nix;
in
{
  users.groups.share.gid = 992;
  users.users.${host.user}.extraGroups = [ "share" ];

  systemd.tmpfiles.rules = [
    "d /mnt/data/share 2770 ${host.user} share -"
  ];

  environment.systemPackages = [ pkgs.rsync ];
}

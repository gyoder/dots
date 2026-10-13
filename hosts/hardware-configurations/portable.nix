{ ... }:

{
  boot.growPartition = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos-portable";
      fsType = "ext4";
      autoResize = true;
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };
}

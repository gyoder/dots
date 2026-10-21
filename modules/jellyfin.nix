{ ... }:

{
  imports = [ ./share.nix ];

  services.jellyfin = {
    enable = true;
    dataDir = "/mnt/data/jellyfin";
    cacheDir = "/mnt/data/jellyfin/cache";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
  };

  users.users.jellyfin.extraGroups = [
    "share"
    "video"
    "render"
  ];

}

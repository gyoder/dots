{ config, ... }:

{
  imports = [ ./share.nix ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/mnt/data/jellyfin";
    configDir = "/mnt/data/jellyfin/config";
    cacheDir = "/mnt/data/jellyfin/cache";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
  };

  users.users.jellyfin.extraGroups = [ "share" "video" "render" ];

  systemd.services.jellyfin = {
    unitConfig.RequiresMountsFor = [ "/mnt/data" ];
    serviceConfig.BindPaths = [
      "${config.services.jellyfin.dataDir}:/var/lib/jellyfin"
      "${config.services.jellyfin.configDir}:/etc/jellyfin"
      "${config.services.jellyfin.cacheDir}:/var/cache/jellyfin"
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/mnt/data/immich/media";
    accelerationDevices = [ "/dev/dri/renderD128" ];
    environment.IMMICH_MEDIA_LOCATION = lib.mkForce "/data";
  };

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.postgresql = {
    package = pkgs.postgresql_16;
    dataDir = "/mnt/data/immich/postgresql/16";
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data/immich 0755 root root -"
    "d ${config.services.immich.mediaLocation} 0700 immich immich -"
    "d /mnt/data/immich/postgresql 0700 postgres postgres -"
    "d ${config.services.postgresql.dataDir} 0700 postgres postgres -"
  ];

  systemd.services = {
    postgresql.unitConfig.RequiresMountsFor = [ "/mnt/data" ];
    immich-server = {
      unitConfig.RequiresMountsFor = [ "/mnt/data" ];
      serviceConfig.BindPaths = [ "${config.services.immich.mediaLocation}:/data" ];
    };
  };
}

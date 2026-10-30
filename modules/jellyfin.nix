{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.jellyfin;
  ssoVersion = "5.1.1";
  ssoArchive = pkgs.fetchurl {
    url = "https://github.com/K0lin/jellyfin-plugin-sso/releases/download/v${ssoVersion}/sso-authentication_${ssoVersion}.zip";
    sha256 = "1c9kaa3rrwws5rgs7vfg57wipvq3zhr344529xss78xxcd3nn4nv";
  };
  ssoPlugin = pkgs.runCommand "jellyfin-sso-${ssoVersion}" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    mkdir -p "$out"
    unzip ${ssoArchive} -d "$out"
  '';
  setupSso = pkgs.writeShellScript "jellyfin-sso-setup" ''
    set -eu
    plugins=${lib.escapeShellArg "${cfg.dataDir}/plugins"}
    mkdir -p "$plugins/SSO-Auth_${ssoVersion}" "$plugins/configurations" ${lib.escapeShellArg cfg.configDir}
    cp --no-preserve=mode ${ssoPlugin}/* "$plugins/SSO-Auth_${ssoVersion}/"
    ${pkgs.python3}/bin/python3 ${./jellyfin-sso.py} \
      "$plugins/configurations/SSO-Auth.xml" \
      "$CREDENTIALS_DIRECTORY/jellyfin-client-secret" \
      ${lib.escapeShellArg "${cfg.configDir}/branding.xml"}
  '';
in
{
  imports = [ ./share.nix ];

  hardware.graphics.extraPackages = [ pkgs.rocmPackages.clr.icd ];

  sops.secrets.jellyfin-client-secret = {
    sopsFile = ../secrets/dijkstra + "/jellyfin-client-secret.json";
    format = "binary";
    restartUnits = [ "jellyfin.service" ];
  };

  systemd.services.jellyfin.serviceConfig = {
    # AMD OpenCL needs the compute device as well as the VA-API render device.
    DeviceAllow = [ "/dev/kfd rw" ];
    LoadCredential = [ "jellyfin-client-secret:${config.sops.secrets.jellyfin-client-secret.path}" ];
    ExecStartPre = lib.mkBefore [ "${setupSso}" ];
  };

  services.jellyfin = {
    enable = true;
    dataDir = "/mnt/data/jellyfin";
    cacheDir = "/mnt/data/jellyfin/cache";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
      };
      enableToneMapping = true;
    };
  };

  users.users.jellyfin.extraGroups = [
    "share"
    "video"
    "render"
  ];

}

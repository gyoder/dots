{ ... }:

{
  services.zipline = {
    enable = true;
    settings = {
      CORE_PORT = 4567;
      CORE_TRUST_PROXY = "true";
      DATASOURCE_LOCAL_DIRECTORY = "/mnt/ext/files";
      FEATURES_USER_REGISTRATION = "false";
      FEATURES_OAUTH_REGISTRATION = "true";
      OAUTH_BYPASS_LOCAL_LOGIN = "true";
      OAUTH_OIDC_CLIENT_ID = "zipline";
      OAUTH_OIDC_AUTHORIZE_URL = "https://auth.gae.moe/api/oidc/authorization";
      OAUTH_OIDC_TOKEN_URL = "https://auth.gae.moe/api/oidc/token";
      OAUTH_OIDC_USERINFO_URL = "https://auth.gae.moe/api/oidc/userinfo";
      OAUTH_OIDC_REDIRECT_URI = "https://l.gae.moe/api/auth/oauth/oidc";
    };
    environmentFiles = [ "/etc/secrets/zipline.env" ];
  };
  users.groups.zipline = { };
  users.users.zipline = {
    isSystemUser = true;
    group = "zipline";
  };
  systemd.services.zipline = {
    unitConfig.RequiresMountsFor = [ "/mnt/ext" ];
    serviceConfig.ReadWritePaths = [ "/mnt/ext/files" ];
  };
  systemd.tmpfiles.rules = [ "d /mnt/ext/files 0750 zipline zipline -" ];
  services.nginx.virtualHosts."l.gae.moe".locations."/".proxyPass = "http://127.0.0.1:4567";
  services.nginx.virtualHosts."l.gae.moe".extraConfig = ''
    proxy_buffering off;
    proxy_request_buffering off;
  '';
}

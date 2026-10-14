{ ... }:

{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.gae.moe";
      listen-http = "127.0.0.1:2586";
      behind-proxy = true;
      auth-default-access = "deny-all";
      enable-login = true;
      enable-signup = false;
      upstream-base-url = "https://ntfy.sh";
    };
  };

  services.nginx.virtualHosts."ntfy.gae.moe".locations."/" = {
    proxyPass = "http://127.0.0.1:2586";
    proxyWebsockets = true;
    extraConfig = "proxy_read_timeout 1h;";
  };
}

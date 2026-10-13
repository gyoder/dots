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

  services.caddy.virtualHosts."ntfy.gae.moe".extraConfig = ''
    reverse_proxy 127.0.0.1:2586
  '';
}

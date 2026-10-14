{ ... }:

{
  services.chhoto-url = {
    enable = true;

    settings = {
      port = 4567;
      site_url = "https://l.gae.moe";
    };

    environmentFiles = [
      "/etc/secrets/url"
    ];
  };

  services.nginx.virtualHosts."l.gae.moe".locations."/".proxyPass = "http://127.0.0.1:4567";
}

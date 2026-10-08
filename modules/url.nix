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

  services.caddy.virtualHosts."l.gae.moe".extraConfig = ''
    reverse_proxy 127.0.0.1:4567
  '';
}

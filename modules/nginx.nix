{
  config,
  lib,
  pkgs,
  ...
}:

let
  tailnet = import ../tailnet.nix;
  auth = import ./nginx-auth.nix { };
  staticSite = root: {
    inherit root;
    extraConfig = ''
      error_page 404 /404.html;

      # Redirect old homepage URLs to /.
      if ($request_uri ~ "^/index\.(?:html|htmlua|php)(?:\?|$)") {
        return 301 /$is_args$args;
      }

      # Redirect explicit page extensions to clean URLs.
      if ($request_uri ~ "^/([^?]+)\.(?:html|htmlua|php)(?:\?|$)") {
        return 301 /$1$is_args$args;
      }
    '';
    locations = {
      "/".tryFiles = "$uri $uri.html $uri/ =404";
      "~ \\.wasm$" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          types {}
          default_type application/wasm;
        '';
      };
      "~ /rss\\.xml$" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          types {}
          default_type application/rss+xml;
        '';
      };
      "= /site.webmanifest" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          types {}
          default_type application/manifest+json;
        '';
      };
      "^~ /.well-known/" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          types {}
          default_type text/plain;
        '';
      };
    };
  };
  proxy = address: {
    locations."/" = {
      proxyPass = address;
      proxyWebsockets = true;
      extraConfig = "proxy_connect_timeout 10s;";
    };
  };
  protectedProxy =
    address:
    let
      host = proxy address;
    in
    host
    // {
      locations = auth.locations // {
        "/" = host.locations."/" // {
          extraConfig = host.locations."/".extraConfig + "\n" + auth.browser;
        };
      };
    };
in
{
  imports = [
    ./authelia.nix
    ./nginx-defaults.nix
  ];

  security.acme = {
    acceptTerms = true;
    defaults.group = "nginx";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    25565
  ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    clientMaxBodySize = "10g";
    proxyTimeout = "300s";
    appendHttpConfig = ''
      proxy_buffering off;
      proxy_request_buffering off;
      proxy_set_header Remote-User "";
      proxy_set_header Remote-Groups "";
      proxy_set_header Remote-Email "";
      proxy_set_header Remote-Name "";
    '';

    virtualHosts = {
      # all of these should be in their respective modules
      "auth.gae.moe" = proxy "http://127.0.0.1:9091";
      "fin.gae.moe" = proxy "http://${tailnet.dijkstra}:8096";
      "files.gae.moe" = protectedProxy "http://${tailnet.dijkstra}:8080";
      "img.gae.moe" = proxy "http://${tailnet.dijkstra}:2283";

      "map.mc.gae.moe" = proxy "http://${tailnet.dijkstra}:8101";

      "*.nate.gae.moe" = (proxy "http://${tailnet.nate-fedora}:80") // {
        enableACME = false;
        forceSSL = false;
      };

      "grace.pink" = staticSite "/mnt/ext/git/www/private/grace.pink/main";
      "beta.grace.pink" = staticSite "/mnt/ext/git/www/private/grace.pink/beta";

      "some.words.gay" = staticSite "/mnt/ext/git/www/private/some.words.gay/main";
      "beta.some.words.gay" = staticSite "/mnt/ext/git/www/private/some.words.gay/beta";
    };
  };

  systemd.sockets.minecraft-proxy = {
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "0.0.0.0:25565" ];
  };
  systemd.services.minecraft-proxy = {
    description = "TCP proxy for Minecraft";
    requires = [ "minecraft-proxy.socket" ];
    serviceConfig = {
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${tailnet.dijkstra}:25565";
      DynamicUser = true;
    };
  };
}

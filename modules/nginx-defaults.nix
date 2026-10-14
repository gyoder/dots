{ lib, pkgs, ... }:

let
  # TODO: make an actual offline page.
  offlinePage = pkgs.writeTextDir "offline.html" ''
    <!doctype html>
    <html lang="en"><head><title>Service temporarily offline</title></head>
    <body><h1>Page Down</h1><p>The backend server is offline. Please check again later.</p></body></html>
  '';
in
{
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config = {
          enableACME = lib.mkDefault true;
          forceSSL = lib.mkDefault true;
          extraConfig = ''
            error_page 502 503 504 /_offline.html;
            proxy_intercept_errors on;
          '';
          locations."= /_offline.html" = {
            root = offlinePage;
            extraConfig = ''
              internal;
              auth_request off;
              rewrite ^ /offline.html break;
              add_header Cache-Control "no-store" always;
            '';
          };
        };
      }
    );
  };
}

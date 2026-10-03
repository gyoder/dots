{
  pkgs,
  lib,
  ...
}:

let
  tailnet = import ../tailnet.nix;
in
{
  networking.firewall.allowedTCPPorts = [
    22
    25565
    80
    443
  ];

  services.caddy = {
    enable = true;

    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/mholt/caddy-l4@v0.1.2"
      ];

      hash = lib.fakeHash;
    };

    globalConfig = ''
      layer4 {
        0.0.0.0:22 {
          route {
            proxy ${tailnet.dijkstra-git}:22
          }
        }

        0.0.0.0:25565 {
          route {
            proxy ${tailnet.dijkstra}:25565
          }
        }
      }
    '';

    extraConfig = ''
      # TODO: make it nice
      (offline_page) {
        handle_errors {
          @offline expression {err.status_code} in [502, 503, 504]

          handle @offline {
            header Content-Type "text/html; charset=utf-8"
            header Cache-Control "no-store"
            respond <<HTML
              <!doctype html>
              <html lang="en">
                <head>
                  <title>Service temporarily offline</title>
                </head>
                <body>
                  <main>
                    <h1>Page Down</h1>
                    <p>If you are seeing this, the backend server is offline. It should be back up soon so check again later.</p>
                    <p class="status">Error {err.status_code}</p>
                  </main>
                </body>
              </html>
              HTML {err.status_code}
          }

          handle {
            respond "{err.status_code} — {err.status_text}" {err.status_code}
          }
        }
      }
    '';

    virtualHosts =
      builtins.mapAttrs
        (
          _: virtualHost:
          virtualHost
          // {
            extraConfig = ''
              import offline_page
              ${virtualHost.extraConfig}
            '';
          }
        )
        {
          "map.mc.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra}:8101
          '';

          "fin.gae.moe".extraConfig = ''
            request_body {
              max_size 10GB
            }

            reverse_proxy ${tailnet.dijkstra}:8096 {
              transport http {
                read_buffer 16KiB
                write_buffer 16KiB
                dial_timeout 10s
                response_header_timeout 300s
                keepalive 60s
              }
            }
          '';

          "files.gae.moe".extraConfig = ''
            request_body {
              max_size 10GB
            }

            reverse_proxy ${tailnet.dijkstra}:8080 {
              transport http {
                read_buffer 16KiB
                write_buffer 16KiB
                dial_timeout 10s
                response_header_timeout 300s
                keepalive 60s
              }
            }
          '';

          "img.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra}:2283
          '';

          "git.gae.moe, git.tools.grace.pink".extraConfig = ''
            request_body {
              max_size 10GB
            }

            reverse_proxy http://${tailnet.dijkstra-git}:3000 {
              flush_interval -1

              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}

              transport http {
                read_buffer 16KiB
                write_buffer 16KiB
                dial_timeout 10s
                response_header_timeout 300s
                keepalive 60s
              }
            }
          '';

          "ci.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra-git}:8000
          '';

          "knot.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra-git}:5555
          '';

          "books.gae.moe".extraConfig = ''
            reverse_proxy localhost:6822
          '';

          "term.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra}:8082 {
              transport http {
                tls_insecure_skip_verify
              }
            }
          '';

          "pds.gae.moe, grace.pds.gae.moe, art.pds.gae.moe".extraConfig = ''
            encode gzip

            request_body {
              max_size 10GB
            }

            handle /xrpc/* {
              reverse_proxy http://${tailnet.lee}:8642 {
                header_up Host {host}
                header_up X-Real-IP {remote_host}
                header_up X-Forwarded-For {remote_host}
                header_up X-Forwarded-Proto {scheme}
                header_up Upgrade {http.request.header.Upgrade}
                header_up Connection "Upgrade"
                flush_interval -1

                transport http {
                  response_header_timeout 86400s
                  keepalive 32s
                  keepalive_idle_conns 32
                }
              }
            }

            handle /oauth/* {
              reverse_proxy http://${tailnet.lee}:8642 {
                header_up Host {host}
                header_up X-Real-IP {remote_host}
                header_up X-Forwarded-For {remote_host}
                header_up X-Forwarded-Proto {scheme}
              }
            }

            handle /.well-known/webfinger {
              rewrite * /helpers/webfinger
              reverse_proxy https://atlogin.net
            }

            handle {
              reverse_proxy http://${tailnet.lee}:8642
            }
          '';
        };
  };
}

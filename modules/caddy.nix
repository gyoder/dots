{ config, ... }:

let
  tailnet = import ../tailnet.nix;
in
{
  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = "/etc/secrets/authelia/jwt";
      storageEncryptionKeyFile = "/etc/secrets/authelia/storage";
      sessionSecretFile = "/etc/secrets/authelia/session";
      oidcHmacSecretFile = "/etc/secrets/authelia/oidc-hmac";
      oidcIssuerPrivateKeyFile = "/etc/secrets/authelia/oidc-key.pem";
    };
    settings = {
      theme = "dark";
      log.level = "info";
      server.address = "tcp://127.0.0.1:9091/";
      server.endpoints.authz = {
        forward-auth = {
          implementation = "ForwardAuth";
          authn_strategies = [ { name = "CookieSession"; } ];
        };
        git = {
          implementation = "AuthRequest";
          authn_strategies = [
            {
              name = "HeaderAuthorization";
              schemes = [ "Basic" ];
            }
          ];
        };
      };
      authentication_backend = {
        password_reset.disable = true;
        password_change.disable = true;
        file.path = "/run/credentials/authelia-main.service/users.yml";
      };
      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = [
              "files.gae.moe"
              "books.gae.moe"
              "term.gae.moe"
              "i.git.gae.moe"
            ];
            policy = "one_factor";
            subject = [ "group:users" ];
          }
        ];
      };
      session.cookies = [
        {
          domain = "gae.moe";
          authelia_url = "https://auth.gae.moe";
          default_redirection_url = "https://files.gae.moe";
        }
      ];
      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
      identity_providers.oidc.clients = [
        {
          client_id = "immich";
          client_name = "Immich";
          client_secret = ''{{ secret (printf "%s/immich-client-secret" (mustEnv "CREDENTIALS_DIRECTORY")) | trim }}'';
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://img.gae.moe/auth/login"
            "https://img.gae.moe/user-settings"
            "app.immich:///oauth-callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_basic";
          userinfo_signed_response_alg = "none";
        }
        {
          client_id = "jellyfin";
          client_name = "Jellyfin";
          client_secret = ''{{ secret (printf "%s/jellyfin-client-secret" (mustEnv "CREDENTIALS_DIRECTORY")) | trim }}'';
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://fin.gae.moe/sso/OID/redirect/authelia" ];
          scopes = [
            "openid"
            "profile"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_post";
          userinfo_signed_response_alg = "none";
        }
      ];
    };
  };

  systemd.services.authelia-main.serviceConfig.LoadCredential = [
    "users.yml:/etc/secrets/authelia/users.yml"
    "immich-client-secret:/etc/secrets/authelia/immich-client-secret"
    "jellyfin-client-secret:/etc/secrets/authelia/jellyfin-client-secret"
  ];
  environment.systemPackages = [ config.services.authelia.instances.main.package ];

  networking.firewall.allowedTCPPorts = [
    # 22
    25565
    80
    443
  ];

  # systemd.sockets.git-ssh-proxy = {
  #   wantedBy = [ "sockets.target" ];
  #   listenStreams = [ "0.0.0.0:22" ];
  # };

  # systemd.services.git-ssh-proxy = {
  #   description = "TCP proxy for Git SSH";
  #   requires = [ "git-ssh-proxy.socket" ];
  #   serviceConfig = {
  #     ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${tailnet.dijkstra-git}:22";
  #     DynamicUser = true;
  #   };
  # };

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

  services.caddy = {
    enable = true;

    extraConfig = ''
      (authelia) {
        request_header -Remote-User
        request_header -Remote-Groups
        request_header -Remote-Email
        request_header -Remote-Name
        forward_auth 127.0.0.1:9091 {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }
      }

      (authelia_git) {
        request_header -Remote-User
        request_header -Remote-Groups
        request_header -Remote-Email
        request_header -Remote-Name
        forward_auth 127.0.0.1:9091 {
          uri /api/authz/git
          header_up X-Original-URL {scheme}://{host}{uri}
          header_up X-Original-Method {method}
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }
      }

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
          "auth.gae.moe".extraConfig = ''
            reverse_proxy 127.0.0.1:9091
          '';

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

            route {
              import authelia
              reverse_proxy ${tailnet.dijkstra}:8080 {
              header_up X-Forwarded-For {http.request.remote.host}
              header_up X-Forwarded-Host {host}
              header_up X-Forwarded-Proto {scheme}
              transport http {
                read_buffer 16KiB
                write_buffer 16KiB
                dial_timeout 10s
                response_header_timeout 300s
                keepalive 60s
              }
            }
            }
          '';

          "img.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra}:2283
          '';

          "ci.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra-git}:8000
          '';

          "knot.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.dijkstra-git}:5555
          '';

          "*.nate.gae.moe".extraConfig = ''
            reverse_proxy ${tailnet.nate-fedora}:80
          '';

          "books.gae.moe".extraConfig = ''
            route {
              import authelia
              reverse_proxy localhost:6822
            }
          '';

          "term.gae.moe".extraConfig = ''
            route {
              import authelia
              reverse_proxy ${tailnet.dijkstra}:8082 {
              transport http {
                tls_insecure_skip_verify
              }
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

          # wtf
          "beta.grace.pink.gae.moe".extraConfig = ''
            handle {
              root * /mnt/ext/git/www/build/private/grace.pink/beta
              file_server
            }
          '';

        };
  };
}

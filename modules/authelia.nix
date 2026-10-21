{ config, ... }:

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
        auth-request = {
          implementation = "AuthRequest";
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
              "i.artifacts.gae.moe"
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
          client_id = "zipline";
          client_name = "Zipline";
          client_secret = ''{{ secret (printf "%s/zipline-client-secret" (mustEnv "CREDENTIALS_DIRECTORY")) | trim }}'';
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://l.gae.moe/api/auth/oauth/oidc" ];
          scopes = [
            "openid"
            "profile"
            "email"
            "offline_access"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
            "refresh_token"
          ];
          token_endpoint_auth_method = "client_secret_post";
          userinfo_signed_response_alg = "none";
        }
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
    "zipline-client-secret:/etc/secrets/authelia/zipline-client-secret"
    "users.yml:/etc/secrets/authelia/users.yml"
    "immich-client-secret:/etc/secrets/authelia/immich-client-secret"
    "jellyfin-client-secret:/etc/secrets/authelia/jellyfin-client-secret"
  ];
  environment.systemPackages = [ config.services.authelia.instances.main.package ];
}

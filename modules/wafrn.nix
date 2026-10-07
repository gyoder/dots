{
  config,
  pkgs,
  lib,
  ...
}:

let
  domain = "wafrn.gae.moe";
  mediaDomain = "media.wafrn.gae.moe";
  cacheDomain = "cache.wafrn.gae.moe";

  pdsDomain = "pds.gae.moe";

  wafrnDir = "/mnt/ext/wafrn";
  secretsFile = "/etc/secrets/wafrn";

  wafrnPort = 8123;

  wafrnEnvironment = {
    COMPOSE_PROJECT_NAME = "wafrn";
    COMPOSE_PROFILES = "bluesky";

    DOMAIN_NAME = domain;
    MEDIA_DOMAIN = mediaDomain;
    CACHE_DOMAIN = cacheDomain;

    FRONTEND_MEDIA_URL = "https://${mediaDomain}";
    FRONTEND_CACHE_URL =
      "https://${cacheDomain}/api/cache?media=";

    ADMIN_USER = "admin";
    ADMIN_EMAIL = "admin@example.com";

    POSTGRES_USER = "wafrn";
    POSTGRES_DBNAME = "wafrn";

    POSTGRES_METRICS_USER = "wafrn_metrics";
    POSTGRES_METRICS_DBNAME = "wafrn_metrics";

    ENABLE_BSKY = "true";

    PDS_DOMAIN_NAME = pdsDomain;
    PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX = "unused-external-pds";

    USE_WORKERS = "true";
    REVIEW_REGISTRATIONS = "true";

    UPLOAD_LIMIT = "52428800";
    LOG_LEVEL = "info";

    ACME_EMAIL = "invalid@example.com";

    DISABLE_REQUIRE_SEND_EMAIL = "true";

    SMTP_HOST = "";
    SMTP_USER = "";
    SMTP_PORT = "587";
    SMTP_FROM = "";

    WEBPUSH_EMAIL = "mailto:admin@example.com";
  };

  publicEnv = pkgs.writeText "wafrn-public.env" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (name: value: "${name}=${value}")
        wafrnEnvironment
    )
    + "\n"
  );

  internalCaddyfile = pkgs.writeText "wafrn-Caddyfile" ''
    {
      admin 0.0.0.0:2019
      auto_https off
    }

    http://${mediaDomain} {
      root * /var/www/html/uploads/
      file_server
    }

    http://${cacheDomain} {
      reverse_proxy backend:9000
    }

    http://${domain} {
      @websocket path /api/websocket/*

      handle @websocket {
        reverse_proxy websocket:9000
      }

      @backend path \
        /api* \
        /fediverse* \
        /contexts* \
        /post* \
        /blog* \
        /.well-known*

      handle @backend {
        reverse_proxy backend:9000
      }

      handle {
        root * /var/www/html/frontend/
        try_files {path} /index.html
        file_server
      }
    }
    '';

  composeOverride = pkgs.writeText "wafrn-nixos.yml" ''
    services:
      frontend:
        ports: !override
          - "127.0.0.1:${toString wafrnPort}:80"
        volumes:
          - "${internalCaddyfile}:/etc/caddy-nixos/Caddyfile:ro"
        command:
          - caddy
          - run
          - --config
          - /etc/caddy-nixos/Caddyfile
          - --adapter
          - caddyfile

      backend:
        deploy:
          replicas: 1

      workers:
        profiles: !override
          - separate-workers

      adminer:
        profiles: !override
          - tools

      bullboard:
        profiles: !override
          - tools

      pds:
        profiles: !override
          - local-pds
  '';

  docker = "${config.virtualisation.docker.package}/bin/docker";

  stopWafrn = pkgs.writeShellScript "wafrn-stop" ''
    cd ${wafrnDir}

    exec ${docker} compose \
      -f docker-compose.default.yml \
      -f ${composeOverride} \
      down
  '';
in
{
  virtualisation.docker = {
    enable = true;

    daemon.settings = {
      "data-root" = "/mnt/ext/docker";

      features = {
        buildkit = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/ext/docker 0710 root root - -"
    "d ${wafrnDir} 0750 root root - -"
  ];

  systemd.services.docker.unitConfig.RequiresMountsFor = [
    "/mnt/ext/docker"
  ];

  environment.systemPackages = with pkgs; [
    git
  ];

  services.caddy = {
    enable = true;

    virtualHosts = {
      "${domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString wafrnPort}
      '';

      "${mediaDomain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString wafrnPort}
      '';

      "${cacheDomain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString wafrnPort}
      '';
    };
  };

  systemd.services.wafrn = {
    description = "Wafrn";

    wantedBy = [
      "multi-user.target"
    ];

    wants = [
      "network-online.target"
    ];

    after = [
      "network-online.target"
      "docker.service"
      "caddy.service"
    ];

    requires = [
      "docker.service"
    ];

    unitConfig.RequiresMountsFor = [
      wafrnDir
    ];

    path = with pkgs; [
      git
      coreutils
      bash
    ];

    environment = wafrnEnvironment // {
      DOCKER_BUILDKIT = "1";
      COMPOSE_BAKE = "true";
    };

    preStart = ''
      if [ ! -d .git ]; then
        ${pkgs.git}/bin/git clone \
          --branch main \
          --single-branch \
          https://codeberg.org/wafrn/wafrn.git \
          .
      fi

      cat \
        ${publicEnv} \
        ${secretsFile} \
        > /run/wafrn/.env

      chmod 600 /run/wafrn/.env

      ln -sfn \
        /run/wafrn/.env \
        ${wafrnDir}/.env
    '';

    script = ''
      exec ${docker} compose \
        -f docker-compose.default.yml \
        -f ${composeOverride} \
        up \
        --build \
        --detach \
        --remove-orphans
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      WorkingDirectory = wafrnDir;
      EnvironmentFile = secretsFile;

      RuntimeDirectory = "wafrn";
      RuntimeDirectoryMode = "0700";

      ExecStop = stopWafrn;

      TimeoutStartSec = 0;
      TimeoutStopSec = 120;
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:

let
  gitDir = "/mnt/ext/git";

  wwwDir = "${gitDir}/www";
  wwwPub = "${wwwDir}/public";
  wwwPriv = "${wwwDir}/private";

  srvDir = "${gitDir}/srv";
  srvPub = "${srvDir}/public";
  srvPriv = "${srvDir}/private";

  mirrorDir = "${gitDir}/repositories/mirrors";

  gitoliteKeys = {
    gitolite-admin = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace_yoder@outlook.com"
    ];

    grace = [ ];
    grace-read = [ ];
  };

  mkGitoliteKey =
    user: key:
    ''command="${pkgs.gitolite}/bin/gitolite-shell ${user}",restrict ${key}'';

  gitoliteAuthorizedKeys =
    lib.concatStringsSep "\n" (
      lib.flatten (
        lib.mapAttrsToList (
          user: keys:
          map (mkGitoliteKey user) keys
        ) gitoliteKeys
      )
    );

  mirrors = [
    {
      url = "https://github.com/gyoder/fun_alloc.git";
      path = "${mirrorDir}/gyoder/fun_alloc.git";
    }
    {
      url = "https://github.com/gyoder/oxipodder.git";
      path = "${mirrorDir}/gyoder/oxipodder.git";
    }
    {
      url = "https://github.com/gyoder/gracegit.git";
      path = "${mirrorDir}/gyoder/gracegit.git";
    }
    {
      url = "https://github.com/gyoder/ColBoy.git";
      path = "${mirrorDir}/gyoder/ColBoy.git";
    }
    {
      url = "https://github.com/gyoder/CircuitPython_4x7_Segment_Display.git";
      path = "${mirrorDir}/gyoder/CircuitPython_4x7_Segment_Display.git";
    }
    {
      url = "https://github.com/gyoder/SpanishAltoidKeyboard.git";
      path = "${mirrorDir}/very_old/gyoder/SpanishAltoidKeyboard.git";
    }
    {
      url = "https://github.com/gyoder/ap_lights.git";
      path = "${mirrorDir}/very_old/gyoder/ap_lights.git";
    }
    {
      url = "https://github.com/Autonomous-Motorsports-Purdue/AMP_Zeus.git";
      path = "${mirrorDir}/Autonomous-Motorsports-Purdue/AMP_Zeus.git";
    }
  ];

in
{
  services.gitolite = {
    enable = true;

    user = "git";
    group = "git";

    dataDir = gitDir;

    adminPubkey =
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace_yoder@outlook.com";

    extraGitoliteRc = ''
      $RC{GIT_CONFIG_KEYS} = 'gitweb\.owner gitweb\.description gitweb\.category';
    '';
  };

  programs.git = {
    enable = true;
    config.init.defaultBranch = "main";
  };


  environment.etc."ssh/git-user-ca.pub" = {
    mode = "0644";
    user = "root";
    group = "root";

    text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuc4HCdyEMu4uiYhlokSXmu+68hkm7j6CqVwjDkCeSj grace.pink
    '';
  };

  environment.etc."ssh/git-principals" = {
    mode = "0644";
    user = "root";
    group = "root";

    text = ''
      command="${pkgs.gitolite}/bin/gitolite-shell grace",restrict t:dev
      command="${pkgs.gitolite}/bin/gitolite-shell grace-read",restrict u:grace
      command="${pkgs.gitolite}/bin/gitolite-shell root",restrict u:root
    '';
  };

  environment.etc."ssh/git-authorized-keys" = {
    mode = "0644";
    user = "root";
    group = "root";

    text = gitoliteAuthorizedKeys + "\n";
  };

  services.openssh = {
    enable = true;

    extraConfig = ''
      Match User git
        TrustedUserCAKeys /etc/ssh/git-user-ca.pub
        AuthorizedPrincipalsFile /etc/ssh/git-principals
        AuthorizedKeysFile /etc/ssh/git-authorized-keys

        PubkeyAuthentication yes
        PasswordAuthentication no
        KbdInteractiveAuthentication no

        DisableForwarding yes
        PermitTTY no
        PermitUserRC no
        X11Forwarding no
    '';
  };


  users.users.caddy.extraGroups = [ "git" ];

  services.fcgiwrap.instances = {
    git-public = {
      process = {
        user = "git";
        group = "git";
      };

      socket = {
        user = "caddy";
        group = "caddy";
        mode = "0600";
      };
    };

    git-private = {
      process = {
        user = "git";
        group = "git";
      };

      socket = {
        user = "caddy";
        group = "caddy";
        mode = "0600";
      };
    };
  };


  services.caddy = {
    enable = true;

    virtualHosts."beta.git.gae.moe".extraConfig = ''
      @gitFetch path_regexp gitFetch ^/.+\.git/(HEAD|info/refs|objects/.*|git-upload-pack)$

      handle @gitFetch {
        reverse_proxy unix/${config.services.fcgiwrap.instances.git-public.socket.address} {
          transport fastcgi {
            env SCRIPT_FILENAME ${pkgs.git}/bin/git-http-backend
            env SCRIPT_NAME /
            env PATH_INFO {http.request.uri.path}

            env GIT_PROJECT_ROOT ${srvPub}
            env GIT_HTTP_EXPORT_ALL 1

            capture_stderr
          }
        }
      }

      handle {
        root * ${wwwPub}
        file_server
      }
    '';

    virtualHosts."igit.k.gae.moe".extraConfig = ''
      @notTailscale {
        not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
      }

      abort @notTailscale

      @gitFetch path_regexp gitFetch ^/.+\.git/(HEAD|info/refs|objects/.*|git-upload-pack)$

      handle @gitFetch {
        reverse_proxy unix/${config.services.fcgiwrap.instances.git-private.socket.address} {
          transport fastcgi {
            env SCRIPT_FILENAME ${pkgs.git}/bin/git-http-backend
            env SCRIPT_NAME /
            env PATH_INFO {http.request.uri.path}

            env GIT_PROJECT_ROOT ${srvPriv}
            env GIT_HTTP_EXPORT_ALL 1

            capture_stderr
          }
        }
      }

      handle {
        root * ${wwwPriv}
        file_server
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${gitDir} 0750 git git -"
    "d ${gitDir}/.ssh 0700 git git -"

    "d ${wwwDir} 0750 git git -"
    "d ${wwwPub} 0750 git git -"
    "d ${wwwPriv} 0750 git git -"

    "d ${srvDir} 0750 git git -"
    "d ${srvPub} 0750 git git -"
    "d ${srvPriv} 0750 git git -"

    "L+ ${srvPub}/grace - - - - ${gitDir}/repositories/grace"

    "L+ ${srvPriv}/private - - - - ${gitDir}/repositories/private"
    "L+ ${srvPriv}/classes - - - - ${gitDir}/repositories/classes"
    "L+ ${srvPriv}/mirrors - - - - ${mirrorDir}"
  ];


  systemd.services.git-mirrors = {
    description = "Mirror Git repos";

    path = [
      pkgs.git
      pkgs.coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "git";
      Group = "git";
    };

    script = lib.concatMapStringsSep "\n" (repo: ''
      mkdir -p "$(dirname ${lib.escapeShellArg repo.path})"

      if [ -d ${lib.escapeShellArg repo.path} ]; then
        git -C ${lib.escapeShellArg repo.path} fetch --prune
      else
        git clone --mirror \
          ${lib.escapeShellArg repo.url} \
          ${lib.escapeShellArg repo.path}
      fi
    '') mirrors;
  };

  systemd.timers.git-mirrors = {
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "15min";
      Persistent = true;
    };
  };
}

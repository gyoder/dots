{
  config,
  pkgs,
  lib,
  ...
}:

let
  # TODO: make this use the home manager in nix-path? set in system.nix
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";

  gitDir = "/mnt/ext/git";
  cgitPriv = "${gitDir}/cgitpriv";
  cgitPub = "${gitDir}/cgitpub";
  gitoliteKeys = {
    gitolite-admin = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace_yoder@outlook.com"
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINySDE+jaYpuAWUdPQf/JcAWETeHgmh+T5Y4GUa7MfeM grace@turing"
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

  fixGitolitePermissions = pkgs.writeShellScript "fix-gitolite-permissions" ''
    set -eu

    ${pkgs.coreutils}/bin/mkdir -p ${gitDir}/.ssh

    ${pkgs.coreutils}/bin/chown git:git ${gitDir}
    ${pkgs.coreutils}/bin/chmod 0750 ${gitDir}

    ${pkgs.coreutils}/bin/chown git:git ${gitDir}/.ssh
    ${pkgs.coreutils}/bin/chmod 0700 ${gitDir}/.ssh

    if [ -e ${gitDir}/.ssh/authorized_keys ]; then
      ${pkgs.coreutils}/bin/chown git:git \
        ${gitDir}/.ssh/authorized_keys

      ${pkgs.coreutils}/bin/chmod 0600 \
        ${gitDir}/.ssh/authorized_keys
    fi
  '';
  publicCgitrc = pkgs.writeText "cgit-public.rc" ''
    virtual-root=/

    css=/cgit.css
    logo=/cgit.png
    favicon=/favicon.ico

    root-title=git.gae.moe
    remove-suffix=1

    enable-git-config=1

    readme=:README.md
    readme=:README
    about-filter=${pkgs.writeShellScript "cgit-about-filter" ''
      case "$1" in
        *.md)
          exec ${pkgs.pandoc}/bin/pandoc \
            --from=gfm \
            --to=html
          ;;
        *)
          exec ${pkgs.coreutils}/bin/cat
          ;;
      esac
    ''}

    scan-path=${cgitPub}
  '';
  privateCgitrc = pkgs.writeText "cgit-private.rc" ''
    virtual-root=/

    css=/cgit.css
    logo=/cgit.png
    favicon=/favicon.ico

    root-title=Private repositories
    remove-suffix=1

    scan-path=${cgitPriv}
  '';
in
{
  services.gitolite = {
    enable = true;

    user = "git";
    group = "git";

    dataDir = "${gitDir}";

    adminPubkey =
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace_yoder@outlook.com";
    extraGitoliteRc = ''
      $RC{GIT_CONFIG_KEYS} = 'gitweb\.owner gitweb\.description gitweb\.category';
    '';
  };
  # home-manager.users.git.home.stateVersion = "26.11";
  # home-manager.users.git.programs.git = {
  #   lfs.enable = true;
  #   # TODO: set repos. can use wildcards?
  #   maintenance.enable = true;
  #   settings.init.defaultBranch = "main";
  # };
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

  services.fcgiwrap.instances = {
    cgit-public = {
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

    cgit-private = {
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
      @cgitStatic path \
        /cgit.css \
        /cgit.js \
        /cgit.png \
        /favicon.ico \
        /robots.txt

      handle @cgitStatic {
        root * ${pkgs.cgit}/cgit
        file_server
      }

      handle {
        reverse_proxy unix/${config.services.fcgiwrap.instances.cgit-public.socket.address} {
          transport fastcgi {
            env SCRIPT_FILENAME ${pkgs.cgit}/cgit/cgit.cgi
            env SCRIPT_NAME /
            env PATH_INFO {http.request.uri.path}
            env CGIT_CONFIG ${publicCgitrc}
            capture_stderr
          }
        }
      }
    '';

    virtualHosts."git.k.gae.moe".extraConfig = ''
      @notTailscale {
        not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
      }

      abort @notTailscale

      @cgitStatic path \
        /cgit.css \
        /cgit.js \
        /cgit.png \
        /favicon.ico \
        /robots.txt

      handle @cgitStatic {
        root * ${pkgs.cgit}/cgit
        file_server
      }

      handle {
        reverse_proxy unix/${config.services.fcgiwrap.instances.cgit-private.socket.address} {
          transport fastcgi {
            env SCRIPT_FILENAME ${pkgs.cgit}/cgit/cgit.cgi
            env SCRIPT_NAME /
            env PATH_INFO {http.request.uri.path}
            env CGIT_CONFIG ${privateCgitrc}
            capture_stderr
          }
        }
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${gitDir} 0750 git git -"
    "d ${gitDir}/.ssh 0700 git git -"

    "d ${cgitPub} 0755 git git -"
    "d ${cgitPriv} 0755 git git -"

    "L+ ${cgitPub}/grace - - - - ${gitDir}/repositories/grace"
    # "L+ ${cgitPub}/person - - - - ${gitDir}/repositories/person"

    "L+ ${cgitPriv}/private - - - - ${gitDir}/repositories/private"
    "L+ ${cgitPriv}/school - - - - ${gitDir}/repositories/school"

  ];

}

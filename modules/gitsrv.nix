{ lib, pkgs, ... }:

let
  gitDir = "/mnt/ext/git";
  sorcery = import ../pkgs/sorcery.nix { inherit pkgs; };
  auth = import ./nginx-auth.nix { };

  instances = {
    public = {
      domain = "git.gae.moe";
      exports = "${gitDir}/srv/public";
      repositories = {
        grace = "${gitDir}/grace";
        forks = "${gitDir}/forks";
      };
    };
    private = {
      domain = "i.git.gae.moe";
      exports = "${gitDir}/srv/private";
      repositories = {
        private = "${gitDir}/private";
        classes = "${gitDir}/classes";
        mirror-gyoder = "${gitDir}/mirrors/gyoder";
        mirror-very-old = "${gitDir}/mirrors/very_old/gyoder";
        mirror-autonomous = "${gitDir}/mirrors/Autonomous-Motorsports-Purdue";
      };
    };
  };

  artifactSymlinks =
    dir: instance:
    lib.mapAttrsToList (
      namespace: path:
      "L+ ${dir}/${namespace} - - - - ${gitDir}/artifacts/${lib.removePrefix "${gitDir}/" path}"
    ) instance.repositories;

  sshCommand = pkgs.writeShellScript "sorcery-ssh-command" ''
    export PATH=${pkgs.git}/bin:$PATH
    export SORCERY_REPOSITORIES=${instances.public.exports}
    export SORCERY_INSTANCE_NAME=git.gae.moe
    export SORCERY_CLONE_URL_BASE=https://git.gae.moe
    export SORCERY_SSH_TUI=${sorcery.sshTuiPackage}/bin/sorcery-ssh-tui
    umask 0007
    exec ${sorcery.sshPackage}/bin/sorcery-ssh
  '';

  mkService = name: instance: {
    description = "Sorcery ${name} Git server";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    unitConfig.RequiresMountsFor = gitDir;
    path = [
      pkgs.git
      pkgs.coreutils
    ];
    environment = {
      SORCERY_REPOSITORIES = "/run/sorcery-${name}/repositories";
      SORCERY_CACHE = "/var/cache/sorcery-${name}";
      SORCERY_SOCKET = "/run/sorcery-${name}/sock";
      SORCERY_INSTANCE_NAME = instance.domain;
      SORCERY_CLONE_URL_BASE = "https://${instance.domain}";
    };
    preStart = ''
      mkdir -p /var/cache/sorcery-${name}/.arborium/${sorcery.grammarVersion}
      cp -L --remove-destination ${sorcery.grammars}/*.wasm /var/cache/sorcery-${name}/.arborium/${sorcery.grammarVersion}/
    '';
    serviceConfig = {
      ExecStart = "${sorcery.package}/bin/sorceryd";
      User = "git";
      Group = "git";
      UMask = "0007";
      RuntimeDirectory = "sorcery-${name}";
      RuntimeDirectoryMode = "0750";
      CacheDirectory = "sorcery-${name}";
      CacheDirectoryMode = "0750";
      BindPaths = lib.mapAttrsToList (
        namespace: path: "-${path}:/run/sorcery-${name}/repositories/${namespace}"
      ) instance.repositories;
      Restart = "on-failure";
      RestartSec = 2;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
    };
  };

  mkHost = name: instance: {
    locations =
      (lib.optionalAttrs (name == "private") auth.locations)
      // {
        "/" = {
          proxyPass = "http://unix:/run/sorcery-${name}/sock";
          extraConfig = lib.optionalString (name == "private") auth.browser;
        };
        "~ ^/_sorcery/(.+/(?:refs|ref/.+/blob/.+))$".extraConfig = ''
          internal;
          auth_request off;
          alias /var/cache/sorcery-${name}/$1;
          types { }
          default_type text/html;
        '';
        "/_sorcery/".extraConfig = ''
          internal;
          auth_request off;
          alias /var/cache/sorcery-${name}/;
        '';
        "/_sorcery-git/".extraConfig = ''
          internal;
          auth_request off;
          alias ${instance.exports}/;
        '';
      }
      // {
        "~ ^/[^/]+/[^/]+/(info/refs|git-upload-pack)$" = {
          proxyPass = "http://unix:/run/sorcery-${name}/sock";
          extraConfig = lib.optionalString (name == "private") auth.git + ''
            proxy_buffering off;
            proxy_request_buffering off;
          '';
        };
      };
  };

  mkArtifactHost = root: protected: {
    inherit root;
    locations = (lib.optionalAttrs protected auth.locations) // {
      "/" = {
        extraConfig = ''
          ${lib.optionalString protected auth.browser}
          autoindex on;
          autoindex_localtime on;
          autoindex_exact_size off;
        '';
      };
    };
  };
in
{
  imports = [ ./githooks.nix ];

  programs.git = {
    enable = true;
    config.init.defaultBranch = "main";
  };

  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = gitDir;
    shell = pkgs.bashInteractive;
  };
  users.users.nginx.extraGroups = [ "git" ];

  environment.etc."ssh/git-user-ca.pub".source = ../ssh-ca.pub;
  environment.etc."ssh/git-principals".text = ''
    t:dev
    u:grace
    u:root
  '';
  environment.etc."ssh/git-principals".mode = "0644";
  environment.etc."ssh/git-authorized-keys".text = ''
    restrict,pty sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace_yoder@outlook.com
  '';
  environment.etc."ssh/git-authorized-keys".mode = "0644";

  services.openssh = {
    enable = true;
    extraConfig = ''
      Match User git
        TrustedUserCAKeys /etc/ssh/git-user-ca.pub
        AuthorizedPrincipalsFile /etc/ssh/git-principals
        AuthorizedKeysFile /etc/ssh/git-authorized-keys
        ForceCommand ${sshCommand}
        PubkeyAuthentication yes
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        DisableForwarding yes
        PermitTTY yes
        PermitUserRC no
        X11Forwarding no
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${gitDir} 0750 git git -"
    "d ${gitDir}/mirrors 0750 git git -"
    "d ${gitDir}/mirrors/very_old 0750 git git -"
    "d ${gitDir}/srv 0750 git git -"
    "d ${gitDir}/srv/artifacts 0750 git git -"
    "d ${gitDir}/srv/artifacts-private 0750 git git -"
  ]
  ++ artifactSymlinks "${gitDir}/srv/artifacts" instances.public
  ++ artifactSymlinks "${gitDir}/srv/artifacts-private" instances.private
  ++ lib.concatLists (
    lib.mapAttrsToList (
      _: instance:
      [ "d ${instance.exports} 0750 git git -" ]
      ++ lib.mapAttrsToList (_: path: "d ${path} 0750 git git -") instance.repositories
      ++ lib.mapAttrsToList (
        namespace: path: "L+ ${instance.exports}/${namespace} - - - - ${path}"
      ) instance.repositories
    ) instances
  );

  systemd.services = lib.mapAttrs' (
    name: instance: lib.nameValuePair "sorcery-${name}" (mkService name instance)
  ) instances;

  services.nginx.virtualHosts =
    lib.mapAttrs' (name: instance: lib.nameValuePair instance.domain (mkHost name instance)) instances
    // {
      "artifacts.gae.moe" = mkArtifactHost "${gitDir}/srv/artifacts" false;

      "i.artifacts.gae.moe" = mkArtifactHost "${gitDir}/srv/artifacts-private" true;
    };
}

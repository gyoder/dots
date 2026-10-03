{
  config,
  pkgs,
  lib,
  ...
}:

let
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

    ${pkgs.coreutils}/bin/mkdir -p /var/lib/git-server/.ssh

    ${pkgs.coreutils}/bin/chown git:git /var/lib/git-server
    ${pkgs.coreutils}/bin/chmod 0750 /var/lib/git-server

    ${pkgs.coreutils}/bin/chown git:git /var/lib/git-server/.ssh
    ${pkgs.coreutils}/bin/chmod 0700 /var/lib/git-server/.ssh

    if [ -e /var/lib/git-server/.ssh/authorized_keys ]; then
      ${pkgs.coreutils}/bin/chown git:git \
        /var/lib/git-server/.ssh/authorized_keys

      ${pkgs.coreutils}/bin/chmod 0600 \
        /var/lib/git-server/.ssh/authorized_keys
    fi
  '';
in
{
  services.gitolite = {
    enable = true;

    user = "git";
    group = "git";

    dataDir = "/var/lib/git-server";

    adminPubkey =
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace_yoder@outlook.com";
  };

  # IMPORTANT:
  # mode != "symlink" makes these REAL /etc files instead of
  # symlinks through /nix/store, which sshd StrictModes rejects.

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

    ports = [
      22
      2222
    ];

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

  systemd.services.gitolite-init.serviceConfig.ExecStartPre =
    lib.mkBefore [
      "+${fixGitolitePermissions}"
    ];

  systemd.tmpfiles.rules = [
    "d /var/lib/git-server 0750 git git -"
    "d /var/lib/git-server/.ssh 0700 git git -"
  ];
}

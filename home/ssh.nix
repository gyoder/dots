{
  host,
  lib,
  ...
}:

let
  hosts = import ../hosts.nix;
  authorizedKeys = lib.concatStringsSep "\n" (
    import ../ssh-keys.nix {
      inherit host;
    }
  );
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings =
      lib.mapAttrs (name: remote: {
        HostName = remote.ssh.hostname or "${name}.i.gae.moe";
        User = remote.user;
        Port = remote.ssh.port or 22;
      }) hosts
      // {
        "*.cs" = {
          HostName = "%h.purdue.edu";
          User = hosts."cs.purdue.edu".user;
          ProxyJump = "${hosts."cs.purdue.edu".user}@data.cs.purdue.edu";
        };
      };
  };

  home.activation.authorizedKeys = lib.mkIf (host.type != "nixos") (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.ssh"
      run chmod 700 "$HOME/.ssh"

      if [[ -z "''${DRY_RUN:-}" ]]; then
        cat > "$HOME/.ssh/authorized_keys" <<'EOF'
      ${authorizedKeys}
      EOF

        chmod 600 "$HOME/.ssh/authorized_keys"
      fi
    ''
  );
}

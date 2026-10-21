{
  lib,
  ...
}:

let
  host = import ../hosts.nix;
  authorizedKeys = lib.concatStringsSep "\n" (
    import ../ssh-keys.nix {
      inherit host;
    }
  );
in
{
  home.activation.authorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/.ssh"
          run chmod 700 "$HOME/.ssh"

          if [[ -z "''${DRY_RUN:-}" ]]; then
            cat > "$HOME/.ssh/authorized_keys" <<'EOF'
    ${authorizedKeys}
    EOF

            chmod 600 "$HOME/.ssh/authorized_keys"
          fi
  '';
}

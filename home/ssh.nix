{
  principals,
  extraKeys ? [ ],
}:

{
  lib,
  ...
}:

let
  authorizedKeys = ''
    cert-authority,principals="t:rebuild,${lib.concatStringsSep "," principals}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuc4HCdyEMu4uiYhlokSXmu+68hkm7j6CqVwjDkCeSj grace.pink
    sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace.pink
    ${lib.concatStringsSep "\n" extraKeys}
  '';
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

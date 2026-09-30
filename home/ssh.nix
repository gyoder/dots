{
  principals,
  extraKeys ? [ ],
}:

{
  lib,
  ...
}:

{
  home.file.".ssh/authorized_keys".text = ''
    cert-authority,principals="${lib.concatStringsSep "," principals}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuc4HCdyEMu4uiYhlokSXmu+68hkm7j6CqVwjDkCeSj grace.pink
    sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace.pink
    ${lib.concatStringsSep "\n" extraKeys}
  '';
}

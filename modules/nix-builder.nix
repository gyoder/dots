{ pkgs, ... }:

let
  certificateAuthority = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ../ssh-ca.pub);
in
{
  users.users.builder = {
    isNormalUser = true;
    description = "Nix remote build account";
    home = "/home/builder";
    createHome = true;
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "cert-authority,principals=\"t:server,t:human\",restrict ${certificateAuthority}"
    ];
  };

  nix.settings.trusted-users = [ "builder" ];
}

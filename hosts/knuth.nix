{ ... }:

let
  host = import ../hosts.nix;
in
{
  imports = [
    ../modules/caddy.nix
    ../modules/gitsrv.nix
    ../modules/wafrn.nix
    ../modules/tailscale.nix
    ../modules/users.nix
    ../modules/dns.nix # does better when last?
  ];

  nix.settings.trusted-users = [
    "root"
    "grace"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };
  networking.hostName = host.name;

  services.openssh = {
    enable = true;
    openFirewall = true;

    ports = [ 22 2222 ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

}

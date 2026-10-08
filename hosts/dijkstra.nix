{ ... }:

let
  host = import ../hosts.nix;
in
{
  imports = [
    ../modules/tailscale.nix
    ../modules/users.nix
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

  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];
  networking.hostName = host.name;

  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

}

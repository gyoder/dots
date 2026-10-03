{ ... }:

let
  host = import ../hosts.nix;
in
{
  imports = [
    ../modules/dns.nix
    ../modules/caddy.nix
    ../modules/gitsrv.nix
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
  networking.hostName = host.name;

  services.openssh = {
    enable = true;
    openFirewall = true;

    ports = [ 2222 ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

}

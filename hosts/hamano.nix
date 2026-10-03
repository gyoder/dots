{ ... }:

let
  host = import ../host.nix;
in
{
  imports = [
    ../hardware-configuration.nix
    ../modules/dns.nix
    ../modules/caddy.nix
    ../modules/auto-update.nix
    ../modules/tailscale.nix
    ../modules/users.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
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

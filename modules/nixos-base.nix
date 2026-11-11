{ host, lib, ... }:
{
  imports = [
    ./secrets.nix
    ./switch-notify.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  networking.hostName = host.name;
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault true;
    ports = lib.mkDefault [
      22
      2222
    ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}

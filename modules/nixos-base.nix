{ ... }:

let
  host = import ../hosts.nix;
in
{
  imports = [ ./switch-notify.nix ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  networking.hostName = host.name;
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];
  environment.sessionVariables.NIX_HOST = host.name;

  services.openssh = {
    enable = true;
    openFirewall = true;
    ports = [
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

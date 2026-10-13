{ config, ... }:

let
  home-manager = (import ../sources.nix).home-manager;
in
{
  nix.settings.trusted-users = [
    "root"
    config.system.primaryUser
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  imports = [
    ../darwin.nix
    "${home-manager}/nix-darwin"
  ];

  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${config.system.primaryUser} = {
      imports = [ ../home.nix ];
    };
  };
}

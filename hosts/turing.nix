{ config, ... }:

let

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  nixpkgs.config.allowUnfree = true;
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
      home.username = config.system.primaryUser;
      home.homeDirectory = config.users.users.${config.system.primaryUser}.home;
    };
  };
}

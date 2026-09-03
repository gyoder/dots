{ config, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  imports = [
    ./darwin.nix
    "${home-manager}/nix-darwin"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${config.system.primaryUser} = {
      imports = [ ./home.nix ];
      home.username = config.system.primaryUser;
      home.homeDirectory = "/Users/${config.system.primaryUser}";
    };
  };
}

{ pkgs, ... }:

let
  host = import ../hosts.nix;
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports = [ "${home-manager}/nixos" ];

  nix.settings.trusted-users = [
    "root"
    "grace"
  ];

  users.users.${host.user} = {
    isNormalUser = true;
    description = host.user;
    home = host.home;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${host.user} = {
      imports = [ ../home.nix ];

      home.username = host.user;
      home.homeDirectory = host.home;
    };
  };
}

{ pkgs, ... }:

let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  host = import ../host.nix;
in
{
  imports = [ "${home-manager}/nixos" ];

  users.users.grace = {
    isNormalUser = true;
    description = "grace";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.grace = {
      imports = [ ../home.nix ];

      home.username = host.user;
      home.homeDirectory = host.home;
    };
  };
}

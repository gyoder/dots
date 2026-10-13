{ pkgs, ... }:

let
  host = import ../hosts.nix;
  home-manager = (import ../sources.nix).home-manager;
in
{
  imports = [ "${home-manager}/nixos" ];

  nix.settings.trusted-users = [ host.user ];

  users.users.${host.user} = {
    isNormalUser = true;
    description = host.user;
    home = host.home;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    shell = pkgs.fish;
    openssh.authorizedKeys.keys = import ../ssh-keys.nix { inherit host; };
  };

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${host.user} = {
      imports = [ ../home.nix ];

    };
  };
}

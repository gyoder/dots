{
  host,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

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
    extraSpecialArgs = { inherit host inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${host.user}.imports = [ ../home.nix ];
  };
}

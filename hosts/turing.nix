{
  config,
  host,
  inputs,
  ...
}:
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
    ../common.nix
    ../darwin.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = { inherit host inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${config.system.primaryUser} = {
      imports = [ ../home.nix ];
    };
  };
}

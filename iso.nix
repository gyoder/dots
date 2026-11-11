{
  host,
  lib,
  modulesPath,
  ...
}:

assert lib.assertMsg (host.name == "portable") "must be portable";
{
  disabledModules = [
    ./common.nix
    ./hosts/hardware-configurations/portable.nix
  ];

  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./hosts/portable.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader.systemd-boot.enable = lib.mkForce false;

  services.getty.autologinUser = lib.mkForce "grace";
  users.users.grace.initialHashedPassword = "";

  installer.cloneConfig = false;
  environment.etc."nixos".source = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: type:
      let
        name = baseNameOf path;
      in
      !(
        builtins.elem name [
          ".git"
          ".jj"
        ]
        || lib.hasPrefix "result" name
      );
  };

  isoImage.edition = "portable";
}

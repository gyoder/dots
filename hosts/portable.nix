{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ../modules/users.nix
    ../modules/tailscale.nix
    ../modules/terminal.nix
    ../modules/nixos-base.nix
  ];

  hardware.enableAllHardware = true;
  hardware.enableRedistributableFirmware = true;

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
  };

  networking.networkmanager.enable = true;
  services.openssh.ports = [ 22 ];

  services.cage = {
    enable = true;
    user = "grace";
    extraArguments = [ "-s" ];
    program = pkgs.writeShellScript "portable-terminal" ''
      exec ${pkgs.foot}/bin/foot --config=/etc/foot/foot.ini
    '';
  };

  services.getty.autologinUser = lib.mkDefault "grace";
  users.users.grace.initialHashedPassword = lib.mkDefault "";

  system.disableInstallerTools = false;
  environment.systemPackages = with pkgs; [
    parted
    dosfstools
    e2fsprogs
  ];

  system.stateVersion = "26.05";

  system.build.usbImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit config lib pkgs;
    name = "nixos-portable-usb";
    baseName = "nixos-portable";
    format = "raw";
    partitionTableType = "efi";
    bootSize = "1024M";
    diskSize = "auto";
    additionalSpace = "2G";
    label = "nixos-portable";
    memSize = 2048;

    contents = [
      {
        source = lib.cleanSourceWith {
          src = ../.;
          filter =
            path: type:
            let
              name = baseNameOf path;
            in
            !(builtins.elem name [ ".jj" ] || lib.hasPrefix "result" name);
        };
        target = "/etc/nixos";
        mode = "u+w";
      }
    ];
  };
}

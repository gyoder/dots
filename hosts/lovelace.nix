{
  host,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../common.nix
    ./hardware-configurations/lovelace.nix
    ../modules/nixos-base.nix
    ../modules/tailscale.nix
    ../modules/users.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.networkmanager.enable = true;

  services = {
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    openssh = {
      ports = [ 22 ];
      openFirewall = false;
    };
  };

  nix.distributedBuilds = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    age
    gitleaks
    gnupg
    nh
    nix-tree
    nixd
    nixfmt
    sops
    ssh-to-age
  ];

  home-manager.users.${host.user}.programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  system.stateVersion = "26.05";
}

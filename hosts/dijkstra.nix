{ ... }:

let
  host = import ../hosts.nix;
in
{
  imports = [
    ../modules/tailscale.nix
    ../modules/users.nix
    ../modules/nixos-base.nix
    ../modules/nix-builder.nix
    ../modules/terminal.nix
    ../modules/immich.nix
    ../modules/jellyfin.nix
    ../modules/samba.nix
    ../modules/backups.nix
    ../modules/copyparty.nix
    ../modules/hotspot.nix
    ../modules/fedora-vm.nix
    ../modules/seedbox.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;

  networking.networkmanager.enable = true;
  services.openssh.openFirewall = false;
  services.tailscale.openFirewall = true;
  fileSystems = {
    "/mnt/data" = {
      device = "/dev/disk/by-uuid/a40705bf-4ee5-4f61-a0df-798a62ab72bc";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt/backup" = {
      device = "/dev/disk/by-uuid/190c9a87-d9d3-4426-8597-8e65bf1cce91";
      fsType = "ext4";
      options = [
        "noatime"
        "nofail"
      ];
    };
  };
  users.users.${host.user} = {
    uid = 1000;
    extraGroups = [ "libvirtd" ];
  };

  system.stateVersion = "26.05";

}

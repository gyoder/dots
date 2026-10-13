{ ... }:

{
  imports = [
    ../modules/dns.nix
    ../modules/caddy.nix
    ../modules/ntfy.nix
    ../modules/gitsrv.nix
    ../modules/url.nix
    ../modules/tailscale.nix
    ../modules/users.nix
    ../modules/nixos-base.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };
  system.stateVersion = "25.11";
  nix.settings.max-jobs = 0;
}

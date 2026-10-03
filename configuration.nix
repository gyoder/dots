{ lib, ... }:
let
  host = import ./hosts.nix;
  # system = import ./system.nix;
in
assert lib.assertMsg (
  host.type != "home"
) "${host.name} is a Home Manager host; use home-manager instead.";
{
  imports = [
    # system.module
    (./hosts + "/${host.name}.nix")
  ]
  ++ lib.optional (host.type == "nixos") (./hosts/hardware-configurations + "/${host.name}.nix");

  nixpkgs.hostPlatform = host.system;
  # nix.settings.nix-path = lib.mkDefault system.module.nix.nixPath;

  security.sudo.extraConfig = ''
    Defaults env_keep += "NIX_HOST"
  '';
}

{ lib, ... }:
let
  host = import ./hosts.nix;
  sources = import ./sources.nix;
in
assert lib.assertMsg (
  host.type != "home"
) "${host.name} is a Home Manager host; use home-manager instead.";
{
  imports = [
    (./hosts + "/${host.name}.nix")
  ]
  ++ lib.optional (host.type == "nixos") (./hosts/hardware-configurations + "/${host.name}.nix");

  nixpkgs.hostPlatform = host.system;
  nixpkgs.pkgs = import sources.nixpkgs {
    system = host.system;
    config.allowUnfree = true;
  };
  nix.nixPath = [
    "nixpkgs=${sources.nixpkgs}"
    "home-manager=${sources.home-manager}"
    "nixos-config=/etc/nixos/configuration.nix"
    "darwin-config=/etc/nix-darwin/configuration.nix"
  ];

  nix.distributedBuilds = host.name != "dijkstra";
  nix.buildMachines = lib.optional (host.name != "dijkstra") {
    hostName = "dijkstra.i.gae.moe";
    sshUser = "builder";
    protocol = "ssh-ng";
    systems = [ "x86_64-linux" ];
    maxJobs = 8;
    speedFactor = 1;
    supportedFeatures = [
      "kvm"
      "big-parallel"
      "nixos-test"
      "benchmark"
    ];
  };
  nix.settings.builders-use-substitutes = true;

  security.sudo.extraConfig = ''
    Defaults env_keep += "NIX_HOST"
  ''
  + lib.optionalString (host.type == "nixos") ''
    Defaults env_keep += "XDG_CONFIG_HOME EDITOR VISUAL JJ_CONFIG"
  '';
}

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
    "darwin=${sources.darwin}"
    "nixos-config=/etc/nixos/configuration.nix"
    "darwin-config=/etc/nix-darwin/configuration.nix"
  ];

  nix.distributedBuilds = host.name != "dijkstra";
  nix.buildMachines = lib.optional (host.name != "dijkstra") {
    hostName = "dijkstra.i.gae.moe";
    sshUser = "builder";
    sshKey = "/root/.ssh/id_ed25519";
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
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  }
  // lib.optionalAttrs (host.type == "nixos") {
    dates = "weekly";
    randomizedDelaySec = "1h";
  }
  // lib.optionalAttrs (host.type == "darwin") {
    interval = [
      {
        Weekday = 0;
        Hour = 3;
        Minute = 15;
      }
    ];
  };
  programs.ssh.knownHosts.dijkstra = {
    hostNames = [
      "dijkstra.i.gae.moe"
      "d.i.gae.moe"
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEAQ463pWxkNc6IxhKMxKaQmvswnkO4UytR0v38ZL0v0";
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "NIX_HOST"
  ''
  + lib.optionalString (host.type == "nixos") ''
    Defaults env_keep += "XDG_CONFIG_HOME EDITOR VISUAL JJ_CONFIG"
  '';
}

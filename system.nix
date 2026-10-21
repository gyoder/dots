{
  configuration ? if (import ./hosts.nix).type == "home" then ./home.nix else ./configuration.nix,
}:

let
  sources = import ./sources.nix;
  host = import ./hosts.nix;
in
if host.type == "home" then
  import "${sources.home-manager}/modules" {
    inherit configuration;
    pkgs = import sources.nixpkgs { system = host.system; };
  }
else if host.type == "darwin" then
  import sources.darwin {
    inherit configuration;
    nixpkgs = sources.nixpkgs;
    system = host.system;
  }
else
  import "${sources.nixpkgs}/nixos" {
    inherit configuration;
    system = host.system;
  }

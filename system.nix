let
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/master.tar.gz";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
  import "${nixpkgs}/nixos" {
  #  home-manager = home-manager;

    configuration = {
      
      imports = [ ./configuration.nix ];

      nix.nixPath = [
        "nixpkgs=${nixpkgs}"
        "home-manager=${home-manager}"
        "nixos-config=${toString ./configuration.nix}"
        "darwin-config=${toString ./configuration.nix}"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];

      nixpkgs.config.allowUnfree = true;
    };
  }

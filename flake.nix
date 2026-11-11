{
  description = "my awesome and cool flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tpb = {
      url = "git+https://git.gae.moe/grace/tpb.git?ref=refs/tags/0.1.4";
      # flake = false;
    };
    sorcery.url = "git+https://git.gae.moe/forks/sorcery?rev=f7e7a6656134fe1d865d9ed377e84076e3d19ea0";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      hosts = import ./hosts.nix;
      hostsOfType = type: lib.filterAttrs (_: host: host.type == type) hosts;
      systems = lib.unique (map (host: host.system) (builtins.attrValues hosts));
      hostArgs = name: {
        inherit inputs;
        host = hosts.${name} // {
          inherit name;
        };
      };
    in
    {
      darwinConfigurations = lib.mapAttrs (
        name: _:
        inputs.darwin.lib.darwinSystem {
          specialArgs = hostArgs name;
          modules = [ (./hosts + "/${name}.nix") ];
        }
      ) (hostsOfType "darwin");

      nixosConfigurations = lib.mapAttrs (
        name: _:
        lib.nixosSystem {
          specialArgs = hostArgs name;
          modules = [ (./hosts + "/${name}.nix") ];
        }
      ) (hostsOfType "nixos");

      homeConfigurations = lib.mapAttrs (
        name: host:
        inputs.home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = hostArgs name;
          pkgs = import nixpkgs {
            system = host.system;
            config.allowUnfree = true;
          };
          modules = [ (./hosts + "/${name}.nix") ];
        }
      ) (hostsOfType "home");

      packages.x86_64-linux.portable-iso =
        (lib.nixosSystem {
          specialArgs = hostArgs "portable";
          modules = [ ./iso.nix ];
        }).config.system.build.isoImage;
      packages.x86_64-linux.portable-usb = self.nixosConfigurations.portable.config.system.build.usbImage;

      devShells = lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages =
              (with pkgs; [
                lixPackageSets.stable.lix
                nixos-rebuild-ng
                coreutils
                openssh
                git
                jujutsu
                jq
                nixfmt
                age
                fish
                gnupg
                gitleaks
                helix
                just
                sops
                ssh-to-age
                (python3.withPackages (p: [ p.pyyaml ]))
              ])
              ++ [ inputs.home-manager.packages.${system}.home-manager ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                inputs.darwin.packages.${system}.darwin-rebuild
              ];

            EDITOR = "hx";

            shellHook = ''
              if [[ $- == *i* ]]; then
                export SHELL=${pkgs.fish}/bin/fish
                exec "$SHELL"
              fi
            '';
          };
        }
      );
    };
}

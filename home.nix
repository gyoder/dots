{
  lib,
  config,
  ...
}:

let
  host = import ./hosts.nix;
in
{
  home = {
    username = host.user;
    homeDirectory = host.home;
    sessionVariables = {
      NIX_HOST = "\${NIX_HOST:-$(hostname -f 2>/dev/null || hostname)}";
    };
  };

  nixpkgs.config.allowUnfree = true;

  imports = [
    ./home/base.nix
    ./home/shell.nix
    ./home/helix.nix
    ./home/tmux.nix
    ./home/vim.nix
    ./home/vcs.nix
  ]
  ++ lib.optional (host.type != "nixos") (import ./home/ssh.nix { })
  ++ lib.optionals (host.name == "turing") [
    ./home/langs.nix
    ./home/packages.nix
    ./home/typst.nix
    ./home/pkgs_mac.nix
    ./home/ghostty.nix
  ]
  ++ lib.optionals (host.name == "cs.purdue.edu") [
    ./home/langs.nix
    ./home/cs_purdue.nix
    ./home/typst.nix
    ./home/linux.nix
  ]
  ++ lib.optionals (host.name == "vulcan") [
    ./home/langs.nix
    ./home/linux.nix
  ]
  ++
    lib.optionals
      (builtins.elem host.name [
        "knuth"
        "dijkstra"
        "portable"
      ])
      [
        ./home/linux.nix
      ];
}

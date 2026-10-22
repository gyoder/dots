{
  lib,
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

  # Weird with cs.purdue.edu
  # nix.gc = lib.mkIf (host.type == "home") {
  #   automatic = true;
  #   dates = "weekly";
  #   randomizedDelaySec = "1h";
  #   options = "--delete-older-than 30d";
  # };

  imports = [
    ./home/base.nix
    ./home/shell.nix
    ./home/nixos-target.nix
    ./home/helix.nix
    ./home/tmux.nix
    ./home/vim.nix
    ./home/vcs.nix
  ]
  ++ lib.optional (host.type != "nixos") ./home/ssh.nix
  ++ lib.optional (lib.hasSuffix "-linux" host.system) ./home/linux.nix
  ++ lib.optional (builtins.elem host.name [
    "turing"
    "cs.purdue.edu"
    "vulcan"
    "dijkstra"
  ]) ./home/langs.nix
  ++ lib.optional (builtins.elem host.name [
    "turing"
    "cs.purdue.edu"
    "dijkstra"
  ]) ./home/typst.nix
  ++ lib.optionals (host.name == "turing") [
    ./home/packages.nix
    ./home/pkgs_mac.nix
    ./home/ghostty.nix
  ]
  ++ lib.optionals (host.name == "cs.purdue.edu") [
    ./home/cs_purdue.nix
  ];
}

{
  lib,
  ...
}:

let
  host = import ./host.nix;
in
{
  home = {
    username = host.user;
    homeDirectory = host.home;
  };

  imports = [
    ./home/base.nix
    ./home/shell.nix
    ./home/helix.nix
    ./home/tmux.nix
    ./home/vim.nix
    ./home/langs.nix
    ./home/vcs.nix
  ]
  ++ lib.optionals (host.name == "turing") [
    ./home/packages.nix
    ./home/typst.nix
    ./home/pkgs_mac.nix
    ./home/ghostty.nix
  ]
  ++ lib.optionals (lib.hasSuffix "cs.purdue.edu" host.name) [
    ./home/cs_purdue.nix
  ];
}

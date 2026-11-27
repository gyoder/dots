{
  host,
  lib,
  ...
}:

{
  home = {
    username = host.user;
    homeDirectory = host.home;
  };

  imports = [
    ./home/base.nix
    ./home/shell.nix
    ./home/ssh.nix
    ./home/helix.nix
    ./home/tmux.nix
    ./home/vim.nix
    ./home/vcs.nix
  ]
  ++ lib.optional (host.name != "knuth") ./home/wezterm.nix
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
  ++ lib.optionals (host.name == "lovelace") [
    ./home/packages.nix
    ./home/ghostty.nix
  ];
}

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
      XDG_CONFIG_HOME = "${host.home}/.config";
    };
  };

  nixpkgs.config.allowUnfree = true;

  imports = [
    # (import ./system.nix).module
    ./home/base.nix
    ./home/shell.nix
    ./home/helix.nix
    ./home/tmux.nix
    ./home/vim.nix
    ./home/vcs.nix
  ]
  ++ lib.optionals (host.name == "turing") [
    (import ./home/ssh.nix {
      principals = [
        "t:human"
        "h:turing"
      ];
    })
    ./home/langs.nix
    ./home/packages.nix
    ./home/typst.nix
    ./home/pkgs_mac.nix
    ./home/ghostty.nix
  ]
  ++ lib.optionals (host.name == "cs.purdue.edu") [
    # Symlinked items from nix store are bad and do not work for ssh
    ./home/langs.nix
    ./home/cs_purdue.nix
    ./home/typst.nix
    ./home/linux.nix
  ]
  ++ lib.optionals (host.name == "vulcan") [
    ./home/langs.nix
    (import ./home/ssh.nix {
      principals = [
        "t:human"
        "t:dev"
        "h:vulcan"
      ];
    })
    ./home/linux.nix
  ]
  ++ lib.optionals (host.name == "knuth") [
    (import ./home/ssh.nix {
      principals = [
        "t:human"
        "t:dev"
        "h:knuth"
      ];
    })
    ./home/linux.nix
  ];
}

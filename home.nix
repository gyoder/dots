{
  lib,
  osConfig ? null,
  ...
}:

let
  detectedHostname =
    if osConfig != null then osConfig.networking.hostName else builtins.getEnv "HOSTNAME";
  detectedUsername = if osConfig != null then osConfig.system.primaryUser else builtins.getEnv "USER";
  detectedHome =
    if osConfig != null then
      osConfig.users.users.${detectedUsername}.home
    else
      let
        envHome = builtins.getEnv "HOME";
      in
      # Will not work on cs.purdue.edu
      if envHome != "" then envHome else "/home/${detectedUsername}";
in
{
  home = {
    username = detectedUsername;
    homeDirectory = detectedHome;
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
  ++ lib.optionals (detectedHostname == "turing") [
    ./home/packages.nix
    ./home/typst.nix
    ./home/pkgs_mac.nix
    ./home/ghostty.nix
  ]
  ++ lib.optionals (lib.hasSuffix "cs.purdue.edu" detectedHostname) [
    ./home/cs_purdue.nix
    ./home/ghostty.nix
  ];
}

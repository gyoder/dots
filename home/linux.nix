{
  host,
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      inetutils
      net-tools
    ]
    ++ lib.optional (host.name != "knuth") pkgs.ghostty;
}

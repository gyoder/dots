{ pkgs, home, ... }:
{
  home.packages = with pkgs; [
    ghostty
    inetutils
    net-tools
  ];
}

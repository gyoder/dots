{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
    inetutils
    net-tools
  ];
}

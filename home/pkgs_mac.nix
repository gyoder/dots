{ pkgs, ... }:

{
  home.packages = with pkgs; [
    utm
    vesktop
  ];
}

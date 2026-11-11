{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    tree-sitter

    sqlite
    podman

    ffmpeg-full
    sox

    # kicad
  ];
}

{ config, pkgs, ... }:

let
  dots = toString ./..;
in
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    montserrat
    fira-math
    corefonts
    source-code-pro
  ];

  home.sessionVariables.TYPST_FONT_PATHS = "${config.home.profileDirectory}/share/fonts";

  home.file."Library/Application Support/typst/packages/local/grace-personal-template/0.1.0".source =
    config.lib.file.mkOutOfStoreSymlink "${dots}/typst";
}

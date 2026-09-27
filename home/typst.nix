{ config, lib, pkgs, ... }:

let
  dots = toString ./..;
  packagePath = "typst/packages/local/grace-personal-template/0.1.0";
  template = {
    source = config.lib.file.mkOutOfStoreSymlink "${dots}/typst";
  };
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

  home.file = lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Application Support/${packagePath}" = template;
  };

  xdg.dataFile = lib.optionalAttrs pkgs.stdenv.isLinux {
    "${packagePath}" = template;
  };
}

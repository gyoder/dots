{ config, ... }:

{
  home = {
    stateVersion = "26.05";

    sessionVariables = {
      XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  xdg.enable = true;
  programs.home-manager.enable = true;
}

{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    package = pkgs.ghostty-bin;
    enableFishIntegration = true;

    settings = {
      clipboard-read = "allow";
      clipboard-write = "allow";
      copy-on-select = true;
      theme = "Rose Pine";
      font-family = "ComicCode Nerd Font SemiBold";
      font-style-italic = "ComicCode Nerd Font Light";
      macos-option-as-alt = "left";
      macos-icon = "blueprint";
      font-feature = [
        "-calt"
        "-liga"
        "-dlig"
      ];
      cursor-click-to-move = true;
      keybind = [
        "global:cmd+grave_accent=toggle_quick_terminal"
        # "alt+i=inspector:toggle"
        "super+t=unbind"
      ];
      quick-terminal-position = "center";
      quick-terminal-animation-duration = 0.1;
    };
  };

}

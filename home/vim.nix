{ ... }:

{
  xdg.configFile."nvim".source = ../vim/.config/nvim;

  home.file.".vim".source = ../vim/.vim;

  home.file.".vimrc".source = ../vim/.vimrc;
}

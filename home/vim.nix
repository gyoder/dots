{ config, ... }:

let
  dots = toString ./..;
in
{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dots}/vim/.config/nvim";

  home.file.".vim".source =
    config.lib.file.mkOutOfStoreSymlink "${dots}/vim/.vim";

  home.file.".vimrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dots}/vim/.vimrc";
}

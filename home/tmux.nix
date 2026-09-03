{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    prefix = "C-\\";
    terminal = "xterm-ghostty";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      {
        plugin = rose-pine;
        extraConfig = ''
          set -g @rose_pine_variant 'main'
          set -g @rose_pine_left_separator ' > '
          set -g @rose_pine_right_separator '  '
          set -g @rose_pine_field_separator ' | '
          set -g @rose_pine_window_separator ':'
          set -g @rose_pine_window_status_separator '  '
        '';
      }
    ];
    extraConfig = ''
      set -g status-position top
      set -g set-clipboard on
      set -g set-titles on
      set -g set-titles-string "#{session_name}"
      setw -g pane-base-index 1
      set -g allow-passthrough all
      set -as terminal-features ",xterm-ghostty:hyperlinks"
      set -ga terminal-overrides ",xterm-ghostty:Tc"

      bind v split-window -h -c "#{pane_current_path}"
      bind b split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
    '';
  };

}

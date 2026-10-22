{ pkgs, ... }:

let
  seshPicker = pkgs.writeShellScript "sesh-picker" ''
    export PATH=${
      pkgs.lib.makeBinPath [
        pkgs.sesh
        pkgs.fzf
        pkgs.tmux
        pkgs.zoxide
        pkgs.fd
      ]
    }:"$PATH"
    selection=$(sesh list --icons | fzf-tmux -p 80%,70% \
      --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
      --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
      --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
      --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
      --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
      --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
      --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
      --preview-window 'right:55%' \
      --preview 'sesh preview {}') || exit 0
    [ -n "$selection" ] || exit 0
    sesh connect "$selection"
  '';
in
{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    prefix = "C-\\\\";
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
      set -s set-clipboard on
      set -s get-clipboard both
      set -g set-titles on
      set -g set-titles-string "#{session_name}"
      setw -g pane-base-index 1
      set -g allow-passthrough all
      set -as terminal-features ",xterm-ghostty:hyperlinks"
      set -ga terminal-overrides ",xterm-ghostty:Tc"

      bind -N "Refresh system clipboard via OSC 52" Y refresh-client -l
      bind -N "Pick a sesh session" T run-shell "${seshPicker}"

      bind v split-window -h -c "#{pane_current_path}"
      bind b split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
      # Alt+1–9: select a window without the tmux prefix.
      bind -n M-1 select-window -t :1
      bind -n M-2 select-window -t :2
      bind -n M-3 select-window -t :3
      bind -n M-4 select-window -t :4
      bind -n M-5 select-window -t :5
      bind -n M-6 select-window -t :6
      bind -n M-7 select-window -t :7
      bind -n M-8 select-window -t :8
      bind -n M-9 select-window -t :9
    '';
  };

}

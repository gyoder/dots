{ config, pkgs, ... }:

{
  xdg.configFile."wezterm/picker.fish".source = ../fish/wezterm-picker.fish;

  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local act = wezterm.action
      local config = wezterm.config_builder()

      config.color_scheme = 'rose-pine'
      config.font = wezterm.font('ComicCode Nerd Font', { weight = 'DemiBold' })
      config.harfbuzz_features = { 'calt=0', 'liga=0', 'dlig=0' }
      config.send_composed_key_when_left_alt_is_pressed = false
      config.use_fancy_tab_bar = true
      config.default_workspace = 'local'

      config.unix_domains = { { name = 'unix' } }
      config.default_domain = 'unix'
      config.default_gui_startup_args = { 'connect', 'unix' }
      local ssh_domains = wezterm.default_ssh_domains()
      for i = 5, 15 do
        local host = string.format('borg%02d', i)
        table.insert(ssh_domains, {
          name = 'SSH:' .. host,
          remote_address = host .. '.cs',
          multiplexing = 'None',
        })
      end
      config.ssh_domains = ssh_domains

      local picker = wezterm.action_callback(function(window, pane)
        local args = { '${pkgs.fish}/bin/fish', '${config.xdg.configHome}/wezterm/picker.fish' }
        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          table.insert(args, 'workspace\t' .. name)
        end
        for _, domain in ipairs(ssh_domains) do
          if domain.name:match('^SSH:') then
            table.insert(args, 'ssh\t' .. domain.name:sub(5) .. '\t' .. domain.remote_address)
          end
        end
        window:perform_action(act.SpawnCommandInNewTab {
          domain = { DomainName = 'unix' },
          args = args,
        }, pane)
      end)

      wezterm.on('user-var-changed', function(window, pane, name, value)
        if name ~= 'workspace_picker' then return end
        local target = wezterm.json_parse(value)
        window:perform_action(act.SwitchToWorkspace {
          name = target.name,
          spawn = {
            domain = { DomainName = 'unix' },
            cwd = target.cwd ~= "" and target.cwd or nil,
            args = target.host ~= "" and { '${pkgs.openssh}/bin/ssh', target.host } or nil,
          },
        }, pane)
        window:perform_action(act.CloseCurrentPane { confirm = false }, pane)
      end)

      local rename_workspace = act.PromptInputLine {
        description = 'New workspace name',
        action = wezterm.action_callback(function(window, pane, line)
          if not line or line == "" then return end
          wezterm.mux.rename_workspace(window:active_workspace(), line)
        end),
      }

      config.keys = {
        { key = 'V', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'H', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'p', mods = 'SUPER', action = picker },
        { key = 'R', mods = 'SUPER|SHIFT', action = rename_workspace },
      }

      wezterm.on('update-right-status', function(window, pane)
        local ok, domain = pcall(function() return pane:get_domain_name() end)
        if not ok then return end
        window:set_right_status(window:active_workspace() .. ' | ' .. domain)
      end)

      return config
    '';
  };
}

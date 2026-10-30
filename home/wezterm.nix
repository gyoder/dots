{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local act = wezterm.action
      local config = wezterm.config_builder()

      config.color_scheme = 'rose-pine'
      config.font = wezterm.font('ComicCode Nerd Font', { weight = 'DemiBold' })
      config.harfbuzz_features = { 'calt=0', 'liga=0', 'dlig=0' }
      config.send_composed_key_when_left_alt_is_pressed = false
      config.use_fancy_tab_bar = false
      config.default_workspace = 'local'
      config.leader = { key = '\\', mods = 'CTRL', timeout_milliseconds = 1000 }

      config.unix_domains = { { name = 'unix' } }
      config.default_gui_startup_args = { 'connect', 'unix' }
      config.ssh_domains = wezterm.default_ssh_domains()

      local function switch(window, pane, name, spawn)
        window:perform_action(act.SwitchToWorkspace {
          name = name,
          spawn = spawn,
        }, pane)
      end

      local remote_project = act.PromptInputLine {
        description = 'Remote project: SSH-config-host:/absolute/path',
        action = wezterm.action_callback(function(window, pane, line)
          if not line or line == "" then return end
          local host, cwd = line:match('^([^:]+):(/.*)$')
          for _, domain in ipairs(config.ssh_domains) do
            if domain.name == 'SSHMUX:' .. (host or "") then
              switch(window, pane, line, {
                domain = { DomainName = domain.name },
                cwd = cwd,
              })
              return
            end
          end
          window:toast_notification('WezTerm',
            'Use a host from ~/.ssh/config and an absolute remote path.', nil, 5000)
        end),
      }

      local picker = wezterm.action_callback(function(window, pane)
        local choices = {}
        local targets = {}
        local function add(label, target)
          local id = tostring(#choices + 1)
          table.insert(choices, { id = id, label = label })
          targets[id] = target
        end

        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          add('workspace  ' .. name, { name = name })
        end
        for _, domain in ipairs(config.ssh_domains) do
          if domain.name:match('^SSHMUX:') then
            local host = domain.name:sub(8)
            add('ssh        ' .. host, {
              name = host,
              spawn = { domain = { DomainName = domain.name } },
            })
          end
        end

        local ok, stdout = wezterm.run_child_process {
          '${pkgs.zoxide}/bin/zoxide', 'query', '-l',
        }
        if ok then
          for path in stdout:gmatch('[^\r\n]+') do
            add('directory  ' .. path, {
              name = path,
              spawn = { domain = { DomainName = 'unix' }, cwd = path },
            })
          end
        end
        add('+ remote project…', { remote = true })

        window:perform_action(act.InputSelector {
          title = 'Workspaces / SSH / projects',
          fuzzy = true,
          choices = choices,
          action = wezterm.action_callback(function(win, selected_pane, id)
            if not id then return end
            local target = targets[id]
            if target.remote then
              win:perform_action(remote_project, selected_pane)
            else
              switch(win, selected_pane, target.name, target.spawn)
            end
          end),
        }, pane)
      end)

      config.keys = {
        { key = 'T', mods = 'LEADER|SHIFT', action = picker },
        { key = 'p', mods = 'SUPER', action = picker },
        { key = '\\', mods = 'LEADER|CTRL', action = act.SendKey { key = '\\', mods = 'CTRL' } },
        { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'b', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
        { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
        { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
        { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
        { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES|DOMAINS' } },
        { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
        { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
        { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
        { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
      }
      for i = 1, 9 do
        table.insert(config.keys, { key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1) })
      end

      wezterm.on('update-right-status', function(window, pane)
        window:set_right_status(window:active_workspace() .. ' | ' .. pane:get_domain_name())
      end)

      return config
    '';
  };
}

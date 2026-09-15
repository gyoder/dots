{
  config,
  lib,
  pkgs,
  ...
}:

let
  paneru = builtins.getFlake "github:karinushka/paneru/bcf248ef60aa4c0b49002161b97bc6e268b05aa7";
  hostName = import ./host.nix;
  primaryUser = if lib.hasSuffix "cs.purdue.edu" hostName then "yoder177" else "grace";
in
{
  imports = [ paneru.darwinModules.paneru ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = hostName;

  environment.systemPackages = [
    pkgs.raycast
    pkgs.thaw
  ];

  system = {
    primaryUser = primaryUser;
    stateVersion = 7;
  };

  users.users.${config.system.primaryUser} = {
    name = config.system.primaryUser;
    home = "/Users/${config.system.primaryUser}";
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  services.paneru = {
    enable = true;

    settings = {
      options = {
        disable_native_tabs = true;
        focus_follows_mouse = false;
        mouse_follows_focus = false;

        animation_speed = 12.0;

        preset_column_widths = [
          0.45
          0.65
          0.9
        ];
        window_resize_cycle = true;
        create_virtual_workspace_automatically = true;
        virtual_workspace_animations = true;

      };

      swipe = {
        sensitivity = 0.35;
        deceleration = 4.0;
        continuous = true;

        gesture = {
          fingers_count = 3;
          direction = "Natural";
          vertical = false;
        };
      };

      padding = {
        top = 5;
        bottom = 5;
        left = 5;
        right = 5;
      };

      windows.all = {
        title = ".*";
        horizontal_padding = 5;
        vertical_padding = 5;
      };

      windows.todoist_quick_add = {
        bundle_id = "com.todoist.mac.Todoist";
        title = "^Todoist$";
        floating = true;
      };

      bindings = {
        window_focus_west = "cmd + shift - h";
        window_focus_east = "cmd + shift - l";

        window_swap_west = "cmd + shift + ctrl - h";
        window_swap_east = "cmd + shift + ctrl - l";

        # window_virtual_south = "cmd - j";
        # window_virtual_north = "cmd - k";

        window_center = "alt - c";
        window_resize = "cmd + shift - f";
        window_balance = "alt - b";

        quit = "ctrl + alt - q";
      };
    };
  };
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "64" = {
          enabled = false;
        };
      };
    };

    "com.raycast.macos" = {
      raycastGlobalHotkey = "Command-49";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}

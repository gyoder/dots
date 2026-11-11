{
  host,
  config,
  pkgs,
  ...
}:

{
  networking.hostName = host.name;

  environment.systemPackages = [
    pkgs.raycast
    pkgs.thaw
  ];

  system = {
    primaryUser = host.user;
    stateVersion = 7;
  };

  users.users.${config.system.primaryUser} = {
    name = config.system.primaryUser;
    home = host.home;
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  system.defaults.CustomUserPreferences = {
    "org.wezfurlong.wezterm".ApplePressAndHoldEnabled = false;
    NSGlobalDomain.NSUserKeyEquivalents = {
      # Command+Option+Shift+J: maximize without entering fullscreen.
      "Fill" = "@~$j";
      # Command+Option+Shift+H/L: tile to the left/right half.
      "Window->Move & Resize->Left" = "@~$h";
      "Window->Move & Resize->Right" = "@~$l";
    };
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "64" = {
          enabled = false;
        };
        # Control+Left: move to the Space on the left.
        "79" = {
          enabled = true;
          value = {
            parameters = [
              65535
              123
              262144
            ];
            type = "standard";
          };
        };
        # Control+Right: move to the Space on the right.
        "81" = {
          enabled = true;
          value = {
            parameters = [
              65535
              124
              262144
            ];
            type = "standard";
          };
        };
      };
    };

    "com.raycast.macos" = {
      raycastGlobalHotkey = "Command-49";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
}

{
  config,
  pkgs,
  ...
}:

let
  host = import ./hosts.nix;
  tailnet = import ./tailnet.nix;
in
{
  networking.hostName = host.name;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "rebuild.sh" ''
      exec /etc/nix-darwin/rebuild.sh "$@"
    '')
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

  environment.etc."auto_master" = {
    knownSha256Hashes = [ "b2aac03248e8f229c703561f5bb059f9be491e5db9f447692398d775a9fb12a5" ];
    text = ''
      +auto_master
      /home auto_home -nobrowse,hidefromfinder
      /Network/Servers -fstab
      /- auto_dijkstra
      /- -static
    '';
  };
  environment.etc."auto_dijkstra".text = ''
    /Volumes/share -fstype=nfs,rw,vers=4.1,tcp,hard,intr,nosuid ${tailnet.dijkstra}:/mnt/data/share
  '';
  system.activationScripts.postActivation.text = ''
    mkdir -p /Volumes/share
    /usr/sbin/automount -vc
  '';

  system.defaults.CustomUserPreferences = {
    NSGlobalDomain.NSUserKeyEquivalents = {
      # Command+Option+Shift+J: toggle native fullscreen.
      "Enter Full Screen" = "@~$j";
      "Exit Full Screen" = "@~$j";
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

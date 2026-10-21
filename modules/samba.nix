{ ... }:

{
  imports = [ ./share.nix ];

  services.samba = {
    enable = true;
    nmbd.enable = false;
    winbindd.enable = false;
    settings = {
      global = {
        "server min protocol" = "SMB2";
        "map to guest" = "Never";
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
      };
      share = {
        path = "/mnt/data/share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "@share";
        "force group" = "share";
        "create mask" = "0660";
        "force create mode" = "0660";
        "directory mask" = "2770";
        "force directory mode" = "2770";
      };
    };
  };

  systemd.services.samba-smbd.unitConfig.RequiresMountsFor = [ "/mnt/data" ];
}

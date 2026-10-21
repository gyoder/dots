{ pkgs, ... }:

{
  imports = [
    ../modules/dns.nix
    ../modules/nginx.nix
    ../modules/ntfy.nix
    ../modules/gitsrv.nix
    ../modules/url.nix
    ../modules/tailscale.nix
    ../modules/users.nix
    ../modules/nixos-base.nix
  ];

  systemd.services.backup-ext = {
    description = "Mirror /mnt/ext to dijkstra";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    onFailure = [ "backup-ext-notify.service" ];
    unitConfig.RequiresMountsFor = [ "/mnt/ext" ];
    path = [
      pkgs.openssh
      pkgs.rsync
      pkgs.util-linux
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      mountpoint -q /mnt/ext
      ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -i /root/.ssh/id_ed25519 grace@d.i.gae.moe \
        'mountpoint -q /mnt/backup && sudo -n mkdir -p /mnt/backup/knuth'
      rsync -aHAX --numeric-ids --delete-delay --stats \
        -e 'ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -i /root/.ssh/id_ed25519' \
        --rsync-path='mountpoint -q /mnt/backup && sudo -n rsync' \
        /mnt/ext/ grace@d.i.gae.moe:/mnt/backup/knuth/
    '';
  };
  systemd.services.backup-ext-notify = {
    description = "Notify when the Knuth backup fails";
    serviceConfig.Type = "oneshot";
    script = ''
      credentials=/etc/secrets/ntfy-nixos-switch.curl
      if [ ! -r "$credentials" ]; then
        echo "Backup failed; notification credentials are unavailable" >&2
        exit 0
      fi
      printf '%s\n' 'Knuth backup to Dijkstra failed. Check journalctl -u backup-ext.service.' |
        ${pkgs.curl}/bin/curl --config "$credentials" \
          --fail --silent --show-error --connect-timeout 3 --max-time 10 \
          --header 'Title: knuth: backup failed' --header 'Priority: high' \
          --data-binary @- --output /dev/null https://ntfy.gae.moe/nixos
    '';
  };
  systemd.timers.backup-ext = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };
  system.stateVersion = "25.11";
  nix = {
    distributedBuilds = true;

    settings = {
      max-jobs = 0;
      builders-use-substitutes = true;
    };

  };
}

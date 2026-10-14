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
    unitConfig.RequiresMountsFor = [ "/mnt/ext" ];
    path = [ pkgs.openssh pkgs.rsync pkgs.util-linux ];
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

    buildMachines = [
      {
        hostName = "d.i.gae.moe";
        sshUser = "builder";
        sshKey = "/root/.ssh/id_ed25519";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        maxJobs = 8;
        speedFactor = 1;
      }
    ];
  };
}

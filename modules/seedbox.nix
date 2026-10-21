{ config, pkgs, ... }:

let
  sources = import ../sources.nix;
  host = import ../hosts.nix;
  media = "/mnt/data/share/media";
  mediaUid = config.users.users.${host.user}.uid;
  exitNode = "100.104.110.13";
  gateway = "192.168.83.1";
  guest = "192.168.83.2";
in
{
  imports = [ "${sources.microvm}/nixos-modules/host" ];

  networking.networkmanager.unmanaged = [ "interface-name:seedbox" ];
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
  systemd.network.networks."30-seedbox" = {
    matchConfig.Name = "seedbox";
    address = [ "${gateway}/30" ];
    networkConfig = {
      ConfigureWithoutCarrier = true;
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
    };
    linkConfig.RequiredForOnline = "no";
  };
  networking.nat = {
    enable = true;
    internalInterfaces = [ "seedbox" ];
  };

  systemd.sockets.seedbox-ssh-proxy = {
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "127.0.0.1:2223" ];
  };
  systemd.services.seedbox-ssh-proxy = {
    description = "Local SSH access to the seedbox";
    requires = [ "seedbox-ssh-proxy.socket" ];
    after = [ "microvm@seedbox.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${guest}:22";
      DynamicUser = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${media} 2770 ${host.user} share -"
  ];

  systemd.services."microvm@seedbox".unitConfig.RequiresMountsFor = [ media ];
  systemd.services."microvm-virtiofsd@seedbox".unitConfig.RequiresMountsFor = [ media ];

  microvm.vms.seedbox.config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ ./microvm-compat.nix ];

      microvm = {
        hypervisor = "qemu";
        vcpu = 2;
        mem = 1536;
        interfaces = [
          {
            type = "tap";
            id = "seedbox";
            mac = "02:00:00:00:51:01";
            tap.vhost = true;
          }
        ];
        volumes = [
          {
            image = "state.img";
            mountPoint = "/var";
            size = 4096;
          }
        ];
        shares = [
          {
            source = "/nix/store";
            mountPoint = "/nix/store";
            tag = "store";
            proto = "virtiofs";
            readOnly = true;
          }
          {
            source = media;
            mountPoint = media;
            tag = "media";
            proto = "virtiofs";
          }
        ];
      };

      networking.hostName = "seedbox";
      networking.useDHCP = false;
      networking.nameservers = [ "9.9.9.9" ];
      services.resolved.enable = false;
      services.nscd.enable = false;
      system.nssModules = lib.mkForce [ ];
      system.nssDatabases.hosts = lib.mkForce [
        "files"
        "dns"
      ];
      systemd.network.networks."20-uplink" = {
        matchConfig.MACAddress = "02:00:00:00:51:01";
        address = [ "${guest}/30" ];
        networkConfig = {
          Gateway = gateway;
          LinkLocalAddressing = "no";
          IPv6AcceptRA = false;
        };
        # Keep recovery SSH working without enabling general LAN access.
        routingPolicyRules = [
          {
            To = "${gateway}/32";
            Table = "main";
            Priority = 2500;
          }
        ];
      };

      services.tailscale = {
        enable = true;
        extraSetFlags = [ "--accept-dns=false" ];
      };
      environment.etc."tailscale/syspolicy.json".text = builtins.toJSON {
        ExitNodeIP = exitNode;
        "ExitNode.AllowOverride" = false;
        ExitNodeAllowLANAccess = "never";
        UseTailscaleDNSSettings = "never";
        UseTailscaleSubnets = "never";
      };
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        hostKeys = [
          {
            path = "/var/lib/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
      users.users.root.openssh.authorizedKeys.keys = import ../ssh-keys.nix {
        host = host // {
          name = "seedbox";
        };
      };

      users.users.transmission = {
        uid = lib.mkForce mediaUid;
        isSystemUser = true;
      };
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        openFirewall = false;
        openRPCPort = false;
        downloadDirPermissions = null;
        settings = {
          download-dir = media;
          incomplete-dir = "${media}/.incomplete";
          incomplete-dir-enabled = true;
          umask = "007";
          rpc-bind-address = "0.0.0.0";
          rpc-authentication-required = false;
          rpc-whitelist-enabled = false;
          rpc-host-whitelist-enabled = false;
          port-forwarding-enabled = false;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${media}/.incomplete 0700 transmission transmission -"
      ];
      systemd.services.transmission-setup.unitConfig.RequiresMountsFor = [ media ];

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        9091
        51413
      ];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 51413 ];
      networking.nftables = {
        enable = true;
        tables.seedbox = {
          family = "inet";
          content = ''
            chain output {
              type filter hook output priority -10; policy accept;
              meta skuid ${toString config.users.users.transmission.uid} oifname != "tailscale0" oifname != "lo" counter drop
            }
          '';
        };
      };
      systemd.services.transmission = {
        requires = [ "nftables.service" ];
        after = [
          "nftables.service"
          "tailscaled.service"
        ];
        unitConfig.RequiresMountsFor = [ media ];
        preStart = ''
          ${pkgs.coreutils}/bin/timeout 10 ${pkgs.tailscale}/bin/tailscale status --json |
            ${pkgs.jq}/bin/jq -e --arg ip ${lib.escapeShellArg exitNode} '
              . as $status |
              .BackendState == "Running" and
              .ExitNodeStatus.Online == true and
              any(.Peer[]?;
                .ID == $status.ExitNodeStatus.ID and
                (.TailscaleIPs | index($ip)) != null
              )
            ' >/dev/null
        '';
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      system.stateVersion = "26.05";
    };
}

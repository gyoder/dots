{ pkgs, ... }:

let
  serial = "2026100601";

  public = {
    lee = "152.44.40.91";
    knuth = "209.50.50.6";
  };

  tailnet = import ../tailnet.nix;

  tailnetRecords = builtins.concatStringsSep "\n" (
    builtins.map (name: "${name}.i IN A ${tailnet.${name}}\n*.${name}.i IN A ${tailnet.${name}}") (builtins.attrNames tailnet)
  );

  mafiaSecondaries = [
    "45.8.201.122"
    "45.8.201.114"
    "158.101.112.125"
  ];

  publicNameservers = ''
    @ IN NS ns1.gae.moe.
    @ IN NS ns1.inx.moe.
    @ IN NS denise.charbroil.me.
    @ IN NS ns1.shad.moe.
  '';

  mkPrimaryZone =
    {
      domain,
      address,
      extraRecords ? "",
    }:
    pkgs.writeText "zone-${domain}" ''
      $ORIGIN ${domain}.
      $TTL 300

      @ IN SOA ns1.gae.moe. hostmaster.gae.moe. (
        ${serial}
        1h
        15m
        1w
        5m
      )

      ${publicNameservers}

      @ IN A ${address}
      * IN A ${address}

      ${extraRecords}
    '';

  mkSecondary =
    master: zones:
    builtins.listToAttrs (
      map (zone: {
        name = zone;
        value = {
          master = false;
          masters = [ master ];
          file = zone;
        };
      }) zones
    );

  mafiaZones =
    mkSecondary "45.8.201.122" [
      "inx.moe"
      "doge-inc.net"
      "foxy.software"
      "swedish.fish"
      "unreliable.email"
      "funmafia.industries"
      "vulcan.moe"
    ]
    // mkSecondary "45.8.201.114" [
      "charbroil.me"
      "puppy.observer"
      "bdsm.equipment"
      "ilovehewlettpackard.com"
    ]
    // mkSecondary "158.101.112.125" [
      "shad.moe"
      "konpeki.solutions"
      "konpekisolutions.com"
    ];

in
{
  services.bind = {
    enable = true;

    cacheNetworks = [
      "127.0.0.0/8"
      "::1/128"
      "100.64.0.0/10"
    ];

    zones = {
      "gae.moe" = {
        master = true;
        slaves = mafiaSecondaries;

        # Potentially could use DNAME forwarding while defining a Quad100 forwarder?
        # https://github.com/tailscale/tailscale/issues/1543#issuecomment-4703759447
        file = mkPrimaryZone {
          domain = "gae.moe";
          address = public.knuth;
          extraRecords = ''
            ns1 IN A ${public.knuth}
            _hi 3600 IN TXT "hi :3"

            ${tailnetRecords}
          '';
        };
      };

      "grace.pink" = {
        master = true;
        slaves = mafiaSecondaries;

        file = mkPrimaryZone {
          domain = "grace.pink";
          address = public.lee;
          extraRecords = ''
            _atproto 3600 IN TXT "did=did:plc:rtokeh2dsmapicefqxkefbfn"
          '';
        };
      };

      "words.gay" = {
        master = true;
        slaves = mafiaSecondaries;

        file = mkPrimaryZone {
          domain = "words.gay";
          address = public.lee;
        };
      };
    }
    // mafiaZones;
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}

{ ... }:

let
  interface = "wlp3s0";
in
{
  networking.networkmanager = {
    enable = true;
    ensureProfiles.profiles.hotspot = {
      connection = {
        id = "PAL4.0";
        type = "wifi";
        interface-name = interface;
        autoconnect = true;
      };
      wifi = {
        mode = "ap";
        ssid = "PAL4.0";
        band = "bg";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "11111111";
      };
      ipv4 = {
        method = "shared";
        address1 = "10.42.0.1/24";
      };
      ipv6.method = "disabled";
    };
  };

  networking.firewall.interfaces.${interface} = {
    allowedUDPPorts = [
      53
      67
    ];
    allowedTCPPorts = [ 53 ];
  };
}

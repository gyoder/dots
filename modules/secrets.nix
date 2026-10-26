{ lib, ... }:

let
  host = import ../hosts.nix;
  sources = import ../sources.nix;
in
{
  imports = [ (sources.sops-nix + "/modules/sops") ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ ];

  sops.secrets =
    lib.optionalAttrs
      (builtins.elem host.name [
        "knuth"
        "dijkstra"
      ])
      {
        ntfy-nixos-switch = {
          sopsFile = ../secrets + "/${host.name}/ntfy-nixos-switch.json";
          format = "binary";
        };
      };
}

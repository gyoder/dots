{ config, ... }:
let
  host = import ./. + "/host.nix";
  conf = import ./. + "/hosts/${host.name}.nix";
in
{
  config = conf;
}

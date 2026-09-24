{ ... }:
let
  host = import ./host.nix;
in
{
  imports = [ (./hosts + "/${host.name}.nix") ];
}

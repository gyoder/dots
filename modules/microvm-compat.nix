{
  config,
  options,
  lib,
  ...
}:

let
  modules = "${(import ../sources.nix).microvm}/nixos-modules/microvm";
in
{
  disabledModules = [
    "${modules}/optimization.nix"
    "${modules}/mounts.nix"
  ];

  imports = [
    (lib.updateManyAttrsByPath [
      {
        path = [
          "content"
          "boot"
          "initrd"
          "systemd"
        ];
        update = attrs: builtins.removeAttrs attrs [ "enable" ];
      }
    ] (import "${modules}/optimization.nix" { inherit config options lib; }))
    (import "${modules}/mounts.nix" {
      inherit lib;
      config = lib.updateManyAttrsByPath [
        {
          path = [
            "boot"
            "initrd"
            "systemd"
          ];
          update = attrs: attrs // { enable = true; };
        }
      ] config;
    })
  ];
}

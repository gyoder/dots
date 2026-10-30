let
  pkgs = import (import ./sources.nix).nixpkgs { };
  sopsEditor = pkgs.writeShellScript "sops-editor" ''
    exec ${pkgs.helix}/bin/hx --cmd 'set auto-format false' --cmd 'set-language text' "$@"
  '';
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    age
    fish
    gnupg
    gitleaks
    helix
    sops
    ssh-to-age
    (python3.withPackages (p: [ p.pyyaml ]))
  ];

  EDITOR = "hx";

  shellHook = ''
    if [[ $- == *i* ]]; then
      export GPG_TTY="$(tty)"
      export SHELL=${pkgs.fish}/bin/fish
      exec "$SHELL" --init-command 'function sops-edit; command env SOPS_EDITOR=${sopsEditor} sops --input-type binary --output-type binary $argv; end'
    fi
  '';
}

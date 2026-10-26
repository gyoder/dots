let
  pkgs = import (import ./sources.nix).nixpkgs { };
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
      exec "$SHELL" --init-command 'function sops-edit; command sops --input-type binary --output-type binary $argv; end'
    fi
  '';
}

mod remote

update:
    nix flake update

rebuild:
    #!/usr/bin/env fish
    switch (hostname -f)
        case turing 'turing.*'
            sudo darwin-rebuild switch --flake .#turing
        case cs.purdue.edu '*.cs.purdue.edu'
            home-manager switch --flake .#cs.purdue.edu
        case vulcan 'vulcan.*'
            home-manager switch --flake .#vulcan
        case '*'
            sudo nixos-rebuild switch --flake ".#"(hostname -s)
    end

target host:
    #!/usr/bin/env fish
    nixos-rebuild switch \
        --flake '.#{{host}}' \
        --build-host builder@dijkstra.i.gae.moe \
        --target-host grace@{{host}}.i.gae.moe \
        --sudo

iso:
    nix build .#packages.x86_64-linux.portable-iso

sops-edit file:
    #!/usr/bin/env fish
    set config (mktemp)
    printf '[editor]\nauto-format = false\n' > $config
    set -lx SOPS_EDITOR "hx --config "(string escape -- $config)
    set -lx GPG_TTY (tty)
    sops --input-type binary --output-type binary {{quote(file)}}
    set result $status
    rm -f $config
    exit $result

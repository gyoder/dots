target host:
    #!/usr/bin/env fish
    set host {{quote(host)}}
    string match --quiet --regex '^[a-zA-Z0-9][a-zA-Z0-9-]*$' -- $host; or exit 2
    set archive (nix flake archive --to ssh://grace@dijkstra.i.gae.moe --json .)
    or exit 1
    set source (printf '%s\n' $archive | jq -er .path)
    or exit 1
    ssh grace@dijkstra.i.gae.moe \
        "sudo -n systemd-run --unit=nixos-remote --collect --service-type=exec --uid=grace \
        --setenv=PATH=/run/current-system/sw/bin:/usr/bin:/bin \
        /run/current-system/sw/bin/nixos-rebuild switch \
        --flake $source#$host --target-host grace@$host.i.gae.moe --sudo"

logs:
    ssh grace@dijkstra.i.gae.moe 'sudo -n journalctl --unit=nixos-remote.service --invocation=0 --lines=100 --follow --no-pager'

gc host:
    ssh {{host}} -- sudo nix-collect-garbage -d

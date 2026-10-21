#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
pins=$(nix eval --impure --json --file "$root/sources.nix")
darwin=$(jq -er '.darwin' <<< "$pins")
nixpkgs=$(jq -er '.nixpkgs' <<< "$pins")
home_manager=$(jq -er '."home-manager"' <<< "$pins")

if [ "$#" -eq 0 ] || [[ "$1" = -* ]]; then
  set -- switch "$@"
fi

exec sudo darwin-rebuild \
  -I "darwin=$darwin" \
  -I "nixpkgs=$nixpkgs" \
  -I "home-manager=$home_manager" \
  -I "darwin-config=$root/configuration.nix" \
  "$@"

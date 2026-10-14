{ pkgs, lib, ... }:

let
  gitDir = "/mnt/ext/git";

  deploy = pkgs.writeShellScript "git-deploy" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.gnutar
        pkgs.coreutils
        pkgs.nix
      ]
    }:$PATH"

    export NIX_PATH="nixpkgs=${pkgs.path}"

    repo="$1"
    rev="$2"
    artifactDir="$3"
    htmlDir="$4"
    ref="$5"

    tmp="$(mktemp -d)"
    finish() {
      status=$?
      trap - EXIT
      rm -rf "$tmp"
      if [ "$status" -eq 0 ]; then
        outcome=succeeded
        tag=white_check_mark
      else
        outcome=failed
        tag=x
      fi
      credentials=/var/lib/git-build-notify/credentials.curl
      if [ -r "$credentials" ]; then
        printf 'Build/deploy %s: %s (%s) at %s\nArtifacts: %s\n' \
          "$outcome" "$repo" "$ref" "$rev" "$artifactDir" |
          ${pkgs.curl}/bin/curl --config "$credentials" \
            --fail --silent --show-error --connect-timeout 3 --max-time 10 \
            --header "Title: Git build/deploy $outcome" \
            --header "Tags: $tag" --data-binary @- --output /dev/null \
            https://ntfy.gae.moe/githooks || true
      fi
      exit "$status"
    }
    trap finish EXIT

    while read -r key; do
      unset "$key"
    done < <(git rev-parse --local-env-vars)

    git -C "$repo" archive "$rev" | tar -xf - -C "$tmp"
    cd "$tmp"

    result="$(nix-build --no-out-link ./hook.nix \
      --argstr artifactDir "$artifactDir" \
      --argstr htmlDir "$htmlDir")"

    mkdir -p "$artifactDir" "$htmlDir"
    "$result/bin/deploy"
  '';
in
{
  users.users.git.linger = true;

  programs.git = {
    enable = true;
    config.core.hooksPath = "/etc/git/hooks";
  };

  environment.etc."git/hooks/post-receive".source = pkgs.writeShellScript "post-receive" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.coreutils
        pkgs.systemd
      ]
    }:$PATH"

    export XDG_RUNTIME_DIR="/run/user/$(id -u)"

    root="${gitDir}"
    repoPath="$(pwd -P)"

    case "$repoPath" in
      "$root"/*) ;;
      *) exit 0 ;;
    esac

    repo="''${repoPath#"$root"/}"
    repo="''${repo%.git}"

    while read -r old new ref; do
      case "$ref" in
        refs/heads/*) name="''${ref#refs/heads/}" ;;
        refs/tags/*) name="''${ref#refs/tags/}" ;;
        *) continue ;;
      esac
      [[ "$new" =~ ^0+$ ]] && continue

      git cat-file -e "$new:hook.nix" 2>/dev/null || continue

      systemd-run --user --no-block --collect \
        --unit="git-deploy-$(date +%s%N)-$RANDOM" \
        "${deploy}" \
        "$repoPath" \
        "$new" \
        "${gitDir}/artifacts/$repo/$name" \
        "${gitDir}/www/$repo/$name" \
        "$ref"

      echo "Queued deployment for $ref" >&2
    done
  '';
}

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
        pkgs.util-linux
      ]
    }:$PATH"

    export NIX_PATH="nixpkgs=${pkgs.path}"

    repo="$1"
    rev="$2"
    artifactDir="$3"
    htmlDir="$4"
    ref="$5"

    mkdir -p "$XDG_RUNTIME_DIR/git-deploy"
    lock=$(printf '%s' "$repo" | sha256sum | cut -d' ' -f1)
    exec 9>"$XDG_RUNTIME_DIR/git-deploy/$lock.lock"
    flock 9

    current=$(git -C "$repo" rev-parse --verify "$ref^{commit}" 2>/dev/null) || exit 0
    if [ "$current" != "$rev" ]; then
      echo "Skipping obsolete deployment for $ref"
      exit 0
    fi

    tmp="$(mktemp -d)"
    finish() {
      status=$?
      trap - EXIT
      rm -rf "$tmp"
      if [ "$status" -eq 0 ]; then
        outcome=succeeded
      else
        outcome=failed
      fi
      credentials=/var/lib/git-build-notify/credentials.curl
      if [ -r "$credentials" ]; then
        printf 'Build/deploy %s: %s (%s) at %s\nArtifacts: %s\n' \
          "$outcome" "$repo" "$ref" "$rev" "$artifactDir" |
          ${pkgs.curl}/bin/curl --config "$credentials" \
            --fail --silent --show-error --connect-timeout 3 --max-time 10 \
            --header "Title: Git build/deploy $outcome" \
            --data-binary @- --output /dev/null \
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

    result="$(nix-build --out-link "$tmp/result" ./hook.nix \
      --argstr artifactDir "$artifactDir" \
      --argstr htmlDir "$htmlDir")"

    mkdir -p "$artifactDir" "$htmlDir"
    "$result/bin/deploy"

    commitDate="$(git -C "$repo" log -1 --format=%ct "$rev^{commit}")"

    find "$artifactDir" "$htmlDir" \
      -exec touch -h -d "@$commitDate" {} +
  '';

  queue = pkgs.writeShellScript "git-queue-deploy" ''
    set -euo pipefail
    export PATH=${
      lib.makeBinPath [
        pkgs.git
        pkgs.coreutils
        pkgs.systemd
      ]
    }:$PATH
    XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export XDG_RUNTIME_DIR
    if [ "$(id -un)" != git ]; then
      echo "Run this command as the git user" >&2
      exit 1
    fi

    repoPath=$(realpath "$1")
    ref="$2"
    rev="$3"
    root=${gitDir}
    case "$repoPath" in
      "$root"/*) ;;
      *) echo "Repository must be beneath $root" >&2; exit 1 ;;
    esac
    case "$ref" in
      refs/heads/*) name="''${ref#refs/heads/}"; otherNamespace=refs/tags ;;
      refs/tags/*) name="''${ref#refs/tags/}"; otherNamespace=refs/heads ;;
      *) exit 0 ;;
    esac
    commit=$(git -C "$repoPath" rev-parse --verify "$rev^{commit}" 2>/dev/null) || exit 0
    git -C "$repoPath" cat-file -e "$commit:hook.nix" 2>/dev/null || exit 0
    others=$(git -C "$repoPath" for-each-ref --format='%(refname)' "$otherNamespace")
    while IFS= read -r other; do
      [ -n "$other" ] || continue
      otherName="''${other#"$otherNamespace"/}"
      if [ "$name" = "$otherName" ] || [[ "$name" = "$otherName/"* ]] || [[ "$otherName" = "$name/"* ]]; then
        if git -C "$repoPath" cat-file -e "$other:hook.nix" 2>/dev/null; then
          echo "Cannot deploy $ref: $other overlaps its output path" >&2
          exit 1
        fi
      fi
    done <<< "$others"

    repo="''${repoPath#"$root"/}"
    repo="''${repo%.git}"
    systemd-run --user --no-block --collect \
      --unit="git-deploy-$(date +%s%N)-$RANDOM" \
      ${deploy} "$repoPath" "$commit" \
      "$root/artifacts/$repo/$name" "$root/www/$repo/$name" "$ref"
    echo "Queued deployment for $ref" >&2
  '';

  regenerate = pkgs.writeShellScriptBin "git-regenerate" ''
    set -euo pipefail
    export PATH=${
      lib.makeBinPath [
        pkgs.git
        pkgs.coreutils
      ]
    }:$PATH
    if [ "$#" -gt 1 ]; then
      echo "Usage: git-regenerate [REPOSITORY]" >&2
      exit 2
    fi
    repo=$(realpath "''${1:-.}")
    refs=$(git -C "$repo" for-each-ref --format='%(refname)' refs/heads refs/tags)
    status=0
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      ${queue} "$repo" "$ref" "$ref" || status=1
    done <<< "$refs"
    exit "$status"
  '';

  mirror = pkgs.writeShellScript "git-mirror" ''
    set -euo pipefail
    export PATH=${
      lib.makeBinPath [
        pkgs.git
        pkgs.coreutils
        pkgs.util-linux
      ]
    }:$PATH
    export GIT_TERMINAL_PROMPT=0
    export GIT_SSH_COMMAND='${pkgs.openssh}/bin/ssh -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=2'
    repo="$1"
    mkdir -p "$XDG_RUNTIME_DIR/git-deploy"
    lock=$(printf '%s' "$repo" | sha256sum | cut -d' ' -f1)
    exec 9>"$XDG_RUNTIME_DIR/git-deploy/$lock-mirror.lock"
    flock 9

    for remote in tangled github codeberg; do
      git -C "$repo" remote get-url --push "$remote" &>/dev/null || continue
      echo "Pushing $repo to $remote..." >&2
      failed=0
      timeout 120 git -C "$repo" push --force "$remote" --all || failed=1
      timeout 120 git -C "$repo" push --force "$remote" --tags || failed=1
      if [ "$failed" -ne 0 ]; then
        credentials=/var/lib/git-build-notify/credentials.curl
        if [ -r "$credentials" ]; then
          printf 'Failed to push %s to %s\n' "$repo" "$remote" |
            ${pkgs.curl}/bin/curl --config "$credentials" \
              --fail --silent --show-error --connect-timeout 3 --max-time 10 \
              --header 'Title: Git mirror failed' \
              --data-binary @- --output /dev/null https://ntfy.gae.moe/githooks || true
        fi
      fi
    done
  '';
in
{
  environment.systemPackages = [ regenerate ];
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

    XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export XDG_RUNTIME_DIR

    root="${gitDir}"
    repoPath="$(pwd -P)"

    case "$repoPath" in
      "$root"/*) ;;
      *) exit 0 ;;
    esac

    updates="$(cat)"

    status=0
    while read -r _old new ref; do
      [[ "$new" =~ ^0+$ ]] && continue
      ${queue} "$repoPath" "$ref" "$new" || status=1
    done <<< "$updates"

    systemd-run --user --no-block --collect \
      --unit="git-mirror-$(date +%s%N)-$RANDOM" ${mirror} "$repoPath" || status=1

    localHook="$repoPath/hooks/post-receive"

    if [ -x "$localHook" ]; then
      printf '%s\n' "$updates" | "$localHook" || status=1
    fi
    exit "$status"
  '';
}

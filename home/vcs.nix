{ ... }:

{
  programs = {
    git = {
      enable = true;
      ignores = [ ".DS_Store" ];
    };

    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Grace Yoder";
          email = "grace_yoder@outlook.com";
        };
        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_ed25519";
        };
        remotes.origin.auto-track-bookmarks = "*";
        remotes.github.auto-track-bookmarks = "*";
        aliases = {
          megasquash = [
            "squash"
            "--from"
            "heads(bookmarks() & ::@-)..@-"
            "--into"
            "@"
          ];

          tug = [
            "bookmark"
            "advance"
            "--to"
            "coalesce(@ ~ empty(), @-)"
          ];

          fn = [
            "util"
            "exec"
            "--"
            "bash"
            "-c"
            ''
              set -euo pipefail

              cd "$JJ_WORKSPACE_ROOT"
              bookmark="''${1:-main}"
              jj git fetch
              jj new "$bookmark"
            ''
            ""
          ];

          tcp = [
            "util"
            "exec"
            "--"
            "bash"
            "-c"
            ''
              set -euo pipefail

              cd "$JJ_WORKSPACE_ROOT"
              jj tug
              if [ "$#" -eq 0 ]; then
                jj new
              else
                jj commit -m "$*"
              fi
              jj git push
            ''
            ""
          ];

          sp = [
            "util"
            "exec"
            "--"
            "bash"
            "-c"
            ''
              set -euo pipefail

              cd "$JJ_WORKSPACE_ROOT"
              jj squash --ignore-immutable
              jj git push
            ''
            ""
          ];
        };
      };
    };

    gh.enable = true;
  };
}

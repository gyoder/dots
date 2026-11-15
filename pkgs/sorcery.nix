{ pkgs, source }:

{
  sshPackage = source.packages.${pkgs.stdenv.hostPlatform.system}.sorcery-ssh;
  sshTuiPackage = source.packages.${pkgs.stdenv.hostPlatform.system}.sorcery-ssh-tui;

  package = source.packages.${pkgs.stdenv.hostPlatform.system}.sorcery-typst.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      cat ${./sorcery-rose-pine.css} >> src/style.css
      cp ${./sorcery-landing.html} landing.html
      cp ${./sorcery-footer.html} footer.html
      substituteInPlace src/render.rs \
        --replace-fail \
          'String::from("<h1>repositories</h1>\n")' \
          'String::from(include_str!("../landing.html"))' \
        --replace-fail \
          '{noscript}{body}</main>\n</body>' \
          '{noscript}{body}</main>\n{footer}\n</body>' \
        --replace-fail \
          'instance_name = escape(instance_name),' \
          'footer = include_str!("../footer.html"), instance_name = escape(instance_name),'
      substituteInPlace src/generate.rs \
        --replace-fail \
          'assert!(!html.contains("<img"));' \
          'assert!(!html.split_once("</main>").unwrap().0.contains("<img"));' \
        --replace-fail \
          'assert!(link.starts_with(['"'"'/'"'"', '"'"'#'"'"']), "{}: relative link {link}", page.display());' \
          'if link.starts_with("https://") || link.starts_with("mailto:") { continue; } assert!(link.starts_with(['"'"'/'"'"', '"'"'#'"'"']), "{}: relative link {link}", page.display());'
    '';
  });
}

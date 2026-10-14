{ pkgs }:

let
  source = builtins.getFlake "git+https://git.t4t.associates/char/sorcery?rev=5e5b89fd84f3fab236aebb245d35107b686842e4";
  manifest = builtins.readFile "${source.outPath}/src/grammar_manifest.rs";
  grammarVersion = builtins.head (builtins.match ''.*VERSION: &str = "([^"]+)";.*'' manifest);
  artifacts = builtins.filter builtins.isList (
    builtins.split ''"([^"]+)" => Some\(\([[:space:]]*([0-9]+),[[:space:]]*"([0-9a-f]+)"'' manifest
  );
in
{
  inherit grammarVersion;
  sshPackage = source.packages.${pkgs.stdenv.hostPlatform.system}.sorcery-ssh;

  package = source.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      cat ${./sorcery-rose-pine.css} >> src/style.css
    '';
  });

  grammars = pkgs.linkFarm "sorcery-grammars-${grammarVersion}" (
    map (artifact: {
      name = "${builtins.elemAt artifact 0}.wasm";
      path = pkgs.fetchurl {
        url = "https://cdn.jsdelivr.net/npm/@arborium/${builtins.elemAt artifact 0}@${grammarVersion}/grammar_bg.wasm";
        sha256 = builtins.elemAt artifact 2;
      };
    }) artifacts
  );
}

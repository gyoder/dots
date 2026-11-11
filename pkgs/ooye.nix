{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_24,
  makeWrapper,
}:

buildNpmPackage {
  pname = "out-of-your-element";
  version = "3.8.2";

  src = fetchzip {
    url = "https://gitdab.com/cadence/out-of-your-element/archive/v3.8.2.tar.gz";
    hash = "sha256-o5T/feGrwKTB0BJ5HZbaw/q2e+/uzSzBBHJHpgrGKnI=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-a/4bZ1tKpI28ndOqdzsB+PsrPpnJTlBygOkMjNSmPY4=";
  nativeBuildInputs = [ makeWrapper ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/ooye $out/bin
    cp -r package.json start.js addbot.js src scripts docs test node_modules $out/lib/ooye/
    makeWrapper ${nodejs_24}/bin/node $out/bin/ooye \
      --add-flags "--enable-source-maps $out/lib/ooye/start.js"
    makeWrapper ${nodejs_24}/bin/node $out/bin/ooye-setup \
      --add-flags "--enable-source-maps $out/lib/ooye/scripts/setup.js"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    ${nodejs_24}/bin/node -e '
      const root = process.argv[1];
      const Database = require(root + "/node_modules/better-sqlite3");
      new Database(":memory:").close();
      require(root + "/node_modules/sharp");
      require(root + "/test/data.js");
      require("node:fs").accessSync(root + "/addbot.js");
    ' "$out/lib/ooye"
    runHook postInstallCheck
  '';

  meta = {
    description = "Matrix-to-Discord appservice bridge";
    homepage = "https://gitdab.com/cadence/out-of-your-element";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "ooye";
  };
}

{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "matrix-continuwuity";
  version = "26.6.0";

  src = fetchurl {
    url = "https://forgejo.ellis.link/continuwuation/continuwuity/releases/download/v26.6.0/conduwuit-linux-static-amd64";
    hash = "sha256-eFi+Fay0uXVJoN1bg1Exyn6lfNA7dhwSjor2S1p6tDg=";
  };

  dontUnpack = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/conduwuit"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/conduwuit" --version | grep -F '26.6.0'
    runHook postInstallCheck
  '';

  meta = {
    description = "Continuwuity pinned before legacy federated invite enforcement";
    homepage = "https://continuwuity.org/";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "conduwuit";
  };
}

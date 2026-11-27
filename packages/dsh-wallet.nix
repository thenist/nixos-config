# dsh-wallet: shows the signed-in DeepSeek account balance beside the
# composer's context usage, and nothing at all while signed out or when the
# account reports no wallet.
#
# The bundle is plain ESM with no build step and no dependencies: index.js is an
# empty Host half, and client.js loads itself through
# window.__ModuleLoader__ and takes React from the module table (like moeseek).
# So this derivation installs the checked-out files as-is; the `web` and `moe`
# profiles' pnpm `link:` dependency points at this store path, which means the
# launcher mounts exactly this pinned revision and nothing is fetched at
# activation time.
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "dsh-wallet";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "thenist";
    repo = "dsh-wallet";
    rev = "2f712f91b1c604059510abf7c85e788943d2626a";
    hash = "sha256-OzxF5U0MXSNvBfNMD81krzCr/eXMHJo2YHGDM2i+Pdw=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r package.json index.js client.js cordis.patch.yml icon.svg \
      README.md README.ko.md locale $out/
    runHook postInstall
  '';

  meta = {
    description = "DeepSeek account wallet balance indicator for the DeepSeek Harness web GUI";
    homepage = "https://github.com/thenist/dsh-wallet";
    platforms = lib.platforms.all;
  };
}

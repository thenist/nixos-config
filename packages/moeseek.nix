# Moeseek: DSH anime "voice" bundle for the assistant. The composer's model
# menu picks a style and a prompt language, and the same choice is available as
# the /moeseek slash command.
#
# It ships no build step and no runtime dependencies: index.js, client.js and
# styles.js are plain ESM and their only imports are relative files or node
# builtins. So this derivation installs the checked-out files as-is; the `moe`
# profile's pnpm `link:` dependency points at this store path, which means the
# launcher mounts exactly this pinned revision and nothing is fetched at
# activation time.
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "moeseek";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "thenist";
    repo = "moeseek";
    rev = "eff55a2f0315dcd389bccc8eae763aa3daf3e5c0";
    hash = "sha256-N0chSJ70SDopYjagCnQOouOOzy35MoVf0RtKXQgok6M=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r package.json index.js styles.js client.js cordis.patch.yml \
      icon.svg README.md locale tests $out/
    runHook postInstall
  '';

  meta = {
    description = "Anime moe voice styles for the DeepSeek Harness assistant";
    homepage = "https://github.com/thenist/moeseek";
    platforms = lib.platforms.all;
  };
}

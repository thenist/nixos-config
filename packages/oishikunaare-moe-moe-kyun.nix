# Oishikunaare-Moe-Moe-Kyun: DSH "house rules" plugin (symbol discipline, no
# emoji, a kaomoji habit, thinking language) plus a CLI/MCP/hook front end.
#
# It ships no build step and no runtime dependencies: `lib/index.js` is the
# committed build output of `src/index.js`, and its only imports are node
# builtins. So this derivation unpacks and installs rather than compiling
# anything, which is also why it needs no node_modules.
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "oishikunaare-moe-moe-kyun";
  version = "0.71.2";

  src = fetchFromGitHub {
    # The repo is Nesarf/...; the README and package.json still name the old
    # owner Nesarf_Mollor, which no longer resolves.
    owner = "Nesarf";
    repo = "Oishikunaare-Moe-Moe-Kyun";
    rev = "70f00a80fc2b83435dedf5a6749e9635b0d1b889";
    hash = "sha256-lsID0aZgqLIt3Pxh+OTmoCCAh6x8x6zMfXXw/iFXTPk=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r package.json cordis.patch.yml lib rules icon.png LICENSE NOTICE \
      README.md CHANGELOG.md bin src adapters $out/
    runHook postInstall
  '';

  meta = {
    description = "Output house rules for every DeepSeek Harness agent, from one global prompt section";
    homepage = "https://github.com/Nesarf/Oishikunaare-Moe-Moe-Kyun";
    # CZGD-PL-1.1 is a custom licence with no SPDX identifier; npm reports it
    # as NOASSERTION. Permissive in effect (attribution + no impersonation),
    # but not an OSI licence.
    license = {
      fullName = "Cheese Gyudon Public Licence 1.1 (CZGD-PL-1.1)";
      url = "https://github.com/Nesarf/Oishikunaare-Moe-Moe-Kyun/blob/main/LICENSE";
      free = true;
    };
    platforms = lib.platforms.all;
  };
})

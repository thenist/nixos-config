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
  version = "0.72.0";

  src = fetchFromGitHub {
    # Personal fork of the upstream project (Nesarf/Oishikunaare-Moe-Moe-Kyun).
    # Pinned to the fork's main at the 0.72.0 release, which adds the Korean
    # locale and the Hangul allow-list fixes. Its README and package.json still
    # name the old owner Nesarf_Mollor, which no longer resolves.
    owner = "thenist";
    repo = "Oishikunaare-Moe-Moe-Kyun";
    rev = "8aa884d0f0ce773f4ec53656168be0cfc4511ee7";
    hash = "sha256-mMu6AyQUxYfNpl27p8tcrpYDp30xuJHgqmVABIiwx5M=";
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
    homepage = "https://github.com/thenist/Oishikunaare-Moe-Moe-Kyun";
    # CZGD-PL-1.1 is a custom licence with no SPDX identifier; npm reports it
    # as NOASSERTION. Permissive in effect (attribution + no impersonation),
    # but not an OSI licence.
    license = {
      fullName = "Cheese Gyudon Public Licence 1.1 (CZGD-PL-1.1)";
      url = "https://github.com/thenist/Oishikunaare-Moe-Moe-Kyun/blob/main/LICENSE";
      free = true;
    };
    platforms = lib.platforms.all;
  };
})

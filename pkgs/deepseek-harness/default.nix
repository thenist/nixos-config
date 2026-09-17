# DeepSeek Harness (`dsh`): DeepSeek's plugin-based agent runtime.
#
# Upstream ships no Nix packaging; the supported install path is the npm
# package `@deepseek-ai/dsh` (README: `npx @deepseek-ai/dsh web`). This
# derivation builds the same dependency closure that `npx` would resolve, so
# the whole tree is pinned by package-lock.json and fetched as a fixed-output
# npm cache at build time.
#
# Regenerate after bumping the version in package.json:
#   cd pkgs/deepseek-harness && npm install --package-lock-only --no-fund --no-audit
#   nix run nixpkgs#prefetch-npm-deps -- pkgs/deepseek-harness/package-lock.json
{ lib
, buildNpmPackage
, makeWrapper
, nodejs
}:

buildNpmPackage (finalAttrs: {
  pname = "dsh";
  version = "0.1.5-rc.1";

  # Only carries package.json + package-lock.json: the CLI itself comes from
  # the lockfile, exactly like `npx @deepseek-ai/dsh`.
  src = ./.;

  npmDepsHash = "sha256-iE7tYtsspNByZYix4ZRicsQoygdlsZOCSBmFcZtdDuQ=";

  # Every native piece (node-pty, koffi, sharp, the @deepseek-ai/node-addon-*
  # packages) ships prebuilt per platform in the npm tarballs; the dependency
  # lifecycle scripts exist for upstream's own dev/CI installs and would only
  # reach for the network or a compiler here.
  npmFlags = [ "--ignore-scripts" ];

  # The npm release ships built JS; there is no source build step.
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r node_modules $out/lib/

    # The shipped `web` profile boots with patchReload: live, so the harness
    # starts its HMR service, which reads Node internals. Upstream normally
    # gets them from the nonstandard `node-addon-require-builtin` addon, which
    # cannot hook the packaged Node ("Unsupported/no-getter"), and its loader
    # then aborts the boot with "--expose-internals is required for HMR
    # service". Asking Node for the internals the service expects keeps `dsh
    # web` (and custom profiles, which also default to live reload) booting.
    makeWrapper ${lib.getExe nodejs} $out/bin/dsh \
      --add-flags "--expose-internals $out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"

    runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness, an everything-is-a-plugin agent runtime";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
})

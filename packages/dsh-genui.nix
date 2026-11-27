# dsh-genui: interactive UI components rendered inline in assistant replies
# from a ```dsh-ui fence — layout, charts, plots, forms, quizzes, mermaid, 3D
# scenes — with actions that flow back to the model. The package ships the host
# half, the browser renderer, and the genui skill.
#
# The npm tarball already contains the built halves under lib/, so this
# derivation does not compile the bundle. The host half imports
# mdast-util-from-markdown at runtime, which a `link:` profile dependency
# cannot resolve from the store copy, so the production dependency tree is
# installed offline into the package's own node_modules from the pinned pnpm
# lock in packages/dsh-genui-deps. The DSH packages it imports are peers and
# resolve from the installation.
{
  lib,
  stdenv,
  fetchurl,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
let
  version = "0.17.0";
  deps = ./dsh-genui-deps;
in
stdenv.mkDerivation {
  pname = "dsh-genui";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@changfenhuang/dsh-genui/-/dsh-genui-${version}.tgz";
    hash = "sha256-//KG/f3F8qDGdBpbWXG0kSstZ6Ob/8U448sbGwW476E=";
  };

  pnpmDeps = fetchPnpmDeps {
    pname = "dsh-genui-deps";
    inherit version;
    src = deps;
    pnpm = pnpm_11;
    fetcherVersion = 5;
    hash = "sha256-GJ6jB0e9eJPKIRJcAJJfuymSbb/f1Pr+WM68MqOeuOo=";
  };

  nativeBuildInputs = [ pnpm_11 pnpmConfigHook ];

  # The profile resolver only looks inside the linked package for its own bare
  # imports, so the dependency tree is installed flat here instead of through
  # pnpm's symlinked virtual store.
  pnpmInstallFlags = [ "--prod" ];

  preConfigure = ''
    export HOME=$TMPDIR/home
    mkdir -p "$HOME"
    cp -r ${deps} $TMPDIR/deps
    chmod -R u+w $TMPDIR/deps
    export pnpmRoot=$TMPDIR/deps
    export pnpm_config_node_linker=hoisted
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out
    cp -r $TMPDIR/deps/node_modules $out/node_modules
    runHook postInstall
  '';

  meta = {
    description = "Generative UI components rendered inline in DeepSeek Harness replies";
    homepage = "https://github.com/omdsh-dev/dsh-genui";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}

# DSH Archive Manager: archive a session from the sidebar session menu, then
# search, sort, filter, restore, or permanently delete archived sessions under
# Settings → Archived.
#
# The npm tarball already ships the built host and browser halves under lib/
# plus the locale resources and the bundle patch, generated against DSH
# 0.2.2-rc.3, so this derivation installs the package as-is and needs no build
# step. home.nix's activation links this store copy into the `web` and `moe`
# profiles, so the launcher mounts this pinned release instead of fetching from
# the registry at activation time.
{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "dsh-archive-manager";
  version = "1.5.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@michengai/dsh-archive-manager/-/dsh-archive-manager-1.5.0.tgz";
    hash = "sha256-NAgSR2OrdTS0C/49kSTovXBuDpLon6fJ1hnBaOIYKmY=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out
    runHook postInstall
  '';

  meta = {
    description = "Archive, restore, and delete DeepSeek Harness sessions from the web GUI";
    homepage = "https://github.com/MichengAI/dsh-archive-manager";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}

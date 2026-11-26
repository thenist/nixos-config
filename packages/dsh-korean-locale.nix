# DSH Korean locale: adds 한국어 to the web GUI's language list, registers Korean
# dictionaries for every shipped client namespace, and scopes a Korean font
# stack to html:lang(ko) without touching code or terminal typography.
#
# The browser half is committed build output (lib/client.js, data/ko.json)
# generated against DSH 0.2.2-rc.3, so this derivation installs the checkout
# as-is and needs no build step. Everything is copied so scripts/verify.mjs can
# check the packaged dictionary coverage without a DSH installation.
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "dsh-korean-locale";
  version = "0.0.1-rc.4";

  src = fetchFromGitHub {
    owner = "nolitor";
    repo = "dsh-korean-locale";
    rev = "fd8e02617beb30b1dc4e6e2d6460561d2c1c5612";
    hash = "sha256-1x4H+unF4R9OvJy0QbUGHvhW1ILVQkwZcLfC8E+VOcg=";
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
    description = "Korean language pack for the DeepSeek Harness web GUI";
    homepage = "https://github.com/nolitor/dsh-korean-locale";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}

# Quickshell resolves QML imports against the configuration directory given
# with -p and drops (blackholes) anything that only resolves via "..", so a
# shell cannot import the shared i18n singleton as "../i18n". Copy the shell's
# QML next to a copy of the singleton instead.
#
# Callers pass the shell directory; the result is a store path that can be
# handed to environment.etc or xdg.configFile.
{ pkgs, dir }:
pkgs.runCommandLocal "quickshell-${baseNameOf dir}" { } ''
  mkdir -p $out
  cp -r ${dir}/. $out/
  cp -r ${./i18n} $out/i18n
''

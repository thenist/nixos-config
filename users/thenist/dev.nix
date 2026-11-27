# Development toolchain. Kept out of environment.systemPackages so root and
# other users do not get it: these land in /etc/profiles/per-user/thenist and
# are only on thenist's PATH. They still end up in the system closure through
# that per-user environment, so this is a scope split, not a size saving.

{ pkgs, ... }:

{
  users.users.thenist.packages = with pkgs; [
    cargo
    gcc
    gnumake
    python315
    rustc
  ];
}

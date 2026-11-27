# niri desktop session, imported by hosts that run niri. The greetd login
# screen lives in greeter.nix and portal setup in common.nix. The bar,
# wallpaper, notifications and idle handling are owned by Noctalia
# (programs/home/noctalia.nix), which starts as a systemd user service; the
# compositor config itself is programs/home/niri.nix.

{ ... }:

{
  programs.niri.enable = true;
}

# niri desktop session, imported by hosts that run niri. The greetd login
# screen lives in greeter.nix and portal setup in common.nix. The bar,
# wallpaper, notifications and idle handling are owned by Noctalia
# (users/thenist/home.nix), which starts as a systemd user service.

{ ... }:

{
  programs.niri.enable = true;
}

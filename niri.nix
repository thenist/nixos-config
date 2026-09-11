# niri desktop session, imported by hosts that run niri. The shared greeter
# lives in greeter.nix and portal setup in common.nix.

{ config, pkgs, ... }:

{
  programs.niri.enable = true;

  greeter.sessionName = "niri";
  greeter.sessionCommand = "/run/current-system/sw/bin/niri-session";

  environment.systemPackages = with pkgs; [
    swaybg # niri has no built-in wallpaper support
  ];
}

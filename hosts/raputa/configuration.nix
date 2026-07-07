# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "raputa"; # Define your hostname.

  # Niri desktop session (registers itself with the greeter and sets up
  # the gnome/gtk portals).
  programs.niri.enable = true;

  greeter.sessionName = "niri";
  greeter.sessionCommand = "/run/current-system/sw/bin/niri-session";

  environment.systemPackages = with pkgs; [
    swaybg # niri has no built-in wallpaper support
  ];
}

{ config, pkgs, ... }:

{
  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.whitesur-gtk-theme
  ];

  gtk = {
    enable = true;

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };

    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
  };

  home.pointerCursor = {
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 24;

    gtk.enable = true;
  };
}

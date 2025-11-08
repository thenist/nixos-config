{ config, pkgs, ... }:

{
  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    gnomeExtensions.search-light
    gnomeExtensions.blur-my-shell
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
    size = 24;
    package = pkgs.whitesur-cursors;
    gtk.enable = true;
  };

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "search-light@icedman.github.com"
        "blur-my-shell@aunetx"
      ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}

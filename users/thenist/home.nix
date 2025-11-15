{ config, pkgs, ... }:

{
  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "25.05";

  programs.vscode = {
    enable = true;
  };

  home.packages = with pkgs; [
    gnomeExtensions.search-light
    gnomeExtensions.dash-to-dock
    gnomeExtensions.open-bar
    gnomeExtensions.coverflow-alt-tab
    gnomeExtensions.no-overview
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
      disable-user-extensions = false;
      enabled-extensions = [
        "search-light@icedman.github.com"
        "dash-to-dock@micxgx.gmail.com"
        "openbar@neuromorph"
        "CoverflowAltTab@palatis.blogspot.com"
        "no-overview@fthx"
      ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      show-battery-percentage = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":minimize,maximize,close";
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri-dark = "file://${config.home.homeDirectory}/.wallpaper.png";
    };

    "org/gnome/shell/extensions/openbar" = {
      bartype = "Trilands";
    };
  };

  home.file.".wallpaper.png".source = ./wallpaper.png;
}

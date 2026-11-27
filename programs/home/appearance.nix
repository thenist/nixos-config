{ pkgs, ... }:

{
  gtk = {
    enable = true;

    # Sets gtk-application-prefer-dark-theme in the GTK 3/4 settings.ini and
    # org.gnome.desktop.interface color-scheme in dconf. Everything that reads
    # the XDG settings portal gets this too (libadwaita, Qt, Chromium/Electron),
    # which is why apps that ignore gtk-theme-name still render dark.
    colorScheme = "dark";

    # Noctalia's GTK templates (programs/home/noctalia.nix) layer its palette over
    # the adw-gtk3 base theme, which the Noctalia docs require for GTK 3.
    # GTK 4 keeps libadwaita's default theme (gtk.gtk4.theme is null at this
    # stateVersion), so only the noctalia.css import colours GTK 4 apps.
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
  };

  # Qt apps ignore the settings portal unless a platform theme is selected;
  # the GTK3 platform theme makes them take the palette/fonts from the GTK
  # theme (adw-gtk3-dark + Noctalia's noctalia.css) and follow the colour
  # scheme. Sets QT_QPA_PLATFORMTHEME for the session (systemd user
  # environment) and for login shells.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.pointerCursor = {
    enable = true;
    name = "WhiteSur-cursors";
    size = 24;
    package = pkgs.whitesur-cursors;
    gtk.enable = true;
  };
}

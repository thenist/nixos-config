# Noctalia Greeter, a greetd login screen. It runs its own wlroots compositor
# and starts the .desktop session named in [session].default (niri ships
# "Niri"). The desktop shell itself is configured in users/thenist/home.nix;
# this file only covers the login screen.

{ pkgs, ... }:

{
  services.displayManager.noctalia-greeter = {
    enable = true;

    settings = {
      # Single-user hosts: open directly on the password step.
      session.default = "Niri";
      user.default = "thenist";

      appearance = {
        # Same palette as the shell (users/thenist/home.nix), so the login
        # screen and the session it starts look like one system.
        scheme = "Catppuccin";
        theme_mode = "dark";
        wallpaper = {
          # Interpolating the path copies the repo wallpaper into the store.
          # The greeter runs as the unprivileged `greeter` user and cannot
          # read /home/thenist (0700), unlike the shell's own wallpaper path.
          path = "${./users/thenist/wallpaper.png}";
          fill_mode = "crop";
          blur = 0.35;
          tint = 0.15;
        };
      };

      clock = {
        enabled = true;
        time_format = "{:%H:%M}";
        date_format = "%A, %x";
      };

      cursor = {
        theme = "WhiteSur-cursors";
        path = "${pkgs.whitesur-cursors}/share/icons";
        size = 24;
      };

      # fcitx5 is not running in the greeter and passwords are ASCII, so match
      # the session's base layout to keep key positions predictable.
      keyboard.layout = "us";
    };
  };
}

# Noctalia Greeter, a greetd login screen. It runs its own wlroots compositor
# and starts the .desktop session named in [session].default (niri ships
# "Niri"). The desktop shell itself is configured in users/thenist/home.nix;
# this file only covers the login screen.

{ pkgs, ... }:

{
  services.displayManager.noctalia-greeter = {
    enable = true;

    # Bottom-anchored login panel and no session picker while niri is the only
    # session. Upstream 1.7.1 hardcodes both (centered panel, always-visible
    # session row); the patch fails loudly on a version bump instead of
    # silently reintroducing them.
    package = pkgs.noctalia-greeter.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./patches/noctalia-greeter-bottom-login.patch ];
    });

    settings = {
      # Single-user hosts: open directly on the password step.
      session.default = "Niri";
      user.default = "thenist";

      appearance = {
        # Same palette as the shell (users/thenist/home.nix), so the login
        # screen and the session it starts look like one system. The greeter
        # has no pure-black switch, so this is Tokyo Night with its normal
        # dark surfaces rather than the shell's true-black variant.
        scheme = "Tokyo-Night";
        theme_mode = "dark";
        # Noctalia's owl brand mark is on by default on the login screen.
        hide_logo = true;
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

      # The greeter's bundled compositor auto-scales from EDID: on this 14"
      # 1080p panel it computed ~1.66 (advertised as scale 2), while niri runs
      # the same panel at 1.25, so the login UI was laid out at a coarser
      # logical size than the session. Pin the laptop panel to match; other
      # outputs (and hosts) keep automatic scaling.
      output.scales = "eDP-1:1.25";

      # fcitx5 is not running in the greeter and passwords are ASCII, so match
      # the session's base layout to keep key positions predictable.
      keyboard.layout = "us";
    };
  };
}

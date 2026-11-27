{ ... }:

{
  # Noctalia v5 (native Wayland shell, not Quickshell) replaces the old
  # custom Quickshell panel and lock screen plus mako, swayidle, swaybg,
  # polkit-gnome and nm-applet. The home-manager module validates the
  # settings at build time and starts the shell as a systemd user service on
  # graphical-session.target, which niri-session starts once niri is ready.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    checkConfig = true;

    settings = {
      shell = {
        # Noctalia's polkit agent replaces polkit_gnome.
        polkit_agent = true;
        # The config is declarative; suppress the first-run wizard so it
        # cannot seed GUI overrides before the user sees the shell.
        setup_wizard_enabled = false;
        niri_overview_type_to_launch_enabled = true;
        niri_overview_close_on_launch_enabled = true;
        launch_apps_as_systemd_services = true;
      };

      # Tokyo Night's deep navy and blue/cyan accents match the wallpaper's
      # near-black sky and icy crystal; pure_black_dark anchors the surfaces to
      # true black so the bar melts into that wallpaper.
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Tokyo-Night";
        pure_black_dark = true;

        # Noctalia renders its palette into the apps that make sense here:
        # GTK 3/4 covers most GUI apps (including libadwaita and the widget
        # colours Firefox picks up), and foot is the terminal. Qt stays on
        # the GTK3 platform theme below, so it inherits the same GTK colours
        # without needing qt6ct and a manually selected scheme.
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [ "gtk3" "gtk4" "foot" "luciole" ];
        };
      };

      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        default.path = "${../../users/thenist/wallpaper.png}";
      };

      # niri's overview backdrop gets a blurred copy of the wallpaper; the
      # layer-rule in the niri config below places the noctalia-backdrop
      # layer inside it.
      backdrop = {
        enabled = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
      };

      notification = {
        enable_daemon = true;
        follow_focused_output = true;
      };

      # Replaces swayidle. niri supports ext_idle_notifier_v1, and Noctalia
      # also locks before sleep via logind's PrepareForSleep.
      idle = {
        behavior.lock = {
          timeout = 600;
          action = "lock";
          enabled = true;
        };
        behavior."screen-off" = {
          timeout = 660;
          action = "screen_off";
          enabled = true;
        };
      };

      bar.main = {
        position = "top";
        thickness = 34;
        start = [ "launcher" "workspaces" ];
        center = [ "clock" ];
        end = [
          "media"
          "tray"
          "notifications"
          "network"
          "bluetooth"
          "volume"
          "power-profile"
          "battery"
          "control-center"
          "session"
        ];
      };

      # The control-center bar widget defaults to the Noctalia owl glyph;
      # replace it with a neutral sliders icon. (The launcher widget already
      # uses the "search" glyph, not the owl.)
      widget."control-center" = {
        glyph = "adjustments";
      };

      lockscreen.enabled = true;
    };
  };
}

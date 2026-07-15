{ config, pkgs, ... }:

let
  ibusPackage = pkgs.ibus-with-plugins.override {
    plugins = with pkgs.ibus-engines; [ hangul ];
  };
  # swayidle's -w waits for commands to exit. Detach the timeout lock so sleep
  # events cannot queue behind it and re-lock the session after authentication.
  idleLockCommand = "quickshell -n -d -p ~/.config/quickshell/lock/shell.qml";
in
{
  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "26.05";

  programs.vscode = {
    enable = true;
  };

  # Keep the Wayland frontend and its XIM bridge in one session-bound cgroup.
  # Each compositor starts this after exporting its Wayland and X11 displays.
  # The frontend can exit cleanly when Xwayland disappears, so on-failure is
  # insufficient here: always restart it while the graphical session is alive.
  systemd.user.services.ibus-wayland = {
    Unit = {
      Description = "IBus Wayland input method frontend";
      ConditionEnvironment = "WAYLAND_DISPLAY";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Slice = "session.slice";
      Environment = [ "XMODIFIERS=@im=ibus" ];
      UnsetEnvironment = [
        "GTK_IM_MODULE"
        "QT_IM_MODULE"
      ];
      ExecStart = "${ibusPackage}/libexec/ibus-ui-gtk3 --enable-wayland-im --exec-daemon --daemon-args \"--xim --panel disable\"";
      Restart = "always";
      RestartSec = "3s";
      TimeoutStopSec = "5s";
    };
  };

  xdg.configFile."driftwm/config.toml".text = ''
    autostart = [
      "${pkgs.systemd}/bin/systemctl --user --no-block restart ibus-wayland.service",
      "quickshell -p ~/.config/quickshell/panel/shell.qml",
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1",
      "nm-applet",
      "mako",
      "swayidle -w timeout 600 '${idleLockCommand}' before-sleep 'sh -c \"${idleLockCommand}; sleep 1\"'"
    ]

    [env]
    XMODIFIERS = "@im=ibus"

    [input.keyboard]
    layout = "kr"
    variant = "kr104"

    [cursor]
    theme = "WhiteSur-cursors"
    size = 24

    [background]
    type = "wallpaper"
    path = "~/.wallpaper.png"

    [decorations]
    bg_color = "#11131a"
    fg_color = "#cad3f5"
    border_width = 1
    border_color = "#2c2f36"
    border_color_focused = "#8aadf4"
    corner_radius = 10
    font = "Adwaita Sans"
    font_size = 11
    font_weight = "medium"

    [keybindings]
    "mod+return" = "exec foot"
    "mod+d" = "exec fuzzel"
    "mod+shift+return" = "exec thunar"
    "mod+l" = "spawn quickshell -n -p ~/.config/quickshell/lock/shell.qml"
    "Print" = "spawn grim - | wl-copy"
    "shift+Print" = 'spawn grim -g "$(slurp -d)" - | wl-copy'
    "XF86AudioRaiseVolume" = "spawn wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
    "XF86AudioLowerVolume" = "spawn wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    "XF86AudioMute" = "spawn wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    "XF86MonBrightnessUp" = "spawn brightnessctl set +5%"
    "XF86MonBrightnessDown" = "spawn brightnessctl set 5%-"
  '';

  # Niri session (used on raputa). Providing a config.kdl replaces niri's
  # built-in defaults, so all binds are spelled out. Mod+L stays as the lock
  # key (matching driftwm), so column-right also gets Mod+Semicolon.
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "kr"
                variant "kr104"
            }
        }
    }

    cursor {
        xcursor-theme "WhiteSur-cursors"
        xcursor-size 24
    }

    environment {
        XMODIFIERS "@im=ibus"
    }

    spawn-at-startup "${pkgs.systemd}/bin/systemctl" "--user" "--no-block" "restart" "ibus-wayland.service"
    spawn-at-startup "sh" "-c" "quickshell -p ~/.config/quickshell/panel/shell.qml"
    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    spawn-at-startup "nm-applet"
    spawn-at-startup "mako"
    spawn-at-startup "sh" "-c" "swaybg -i ~/.wallpaper.png -m fill"
    spawn-at-startup "swayidle" "-w" "timeout" "600" "${idleLockCommand}" "before-sleep" "${idleLockCommand}; sleep 1"

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshot from %Y-%m-%d %H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    layout {
        gaps 10

        focus-ring {
            width 1
            active-color "#8aadf4"
            inactive-color "#2c2f36"
        }

        border {
            off
        }
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+Return { spawn "foot"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Shift+Return { spawn "thunar"; }
        Mod+L { spawn "sh" "-c" "quickshell -n -p ~/.config/quickshell/lock/shell.qml"; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "+5%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }

        Mod+Q { close-window; }

        Mod+Left { focus-column-left; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H { focus-column-left; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+Semicolon { focus-column-right; }

        Mod+Ctrl+Left { move-column-left; }
        Mod+Ctrl+Down { move-window-down; }
        Mod+Ctrl+Up { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+J { move-window-down; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+Semicolon { move-column-right; }

        Mod+Home { focus-column-first; }
        Mod+End { focus-column-last; }

        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up { move-workspace-up; }

        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        Mod+BracketLeft { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }

        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-window-height; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+C { center-column; }
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        Mod+V { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }

        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        Mod+Shift+P { power-off-monitors; }
        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }
    }
  '';

  # ibus-hangul's event-forwarding workaround consumes Space/Enter and re-sends
  # them via forward_key_event, which the ibus Wayland IM frontend never
  # delivers to the client. Disable it so unhandled keys are re-injected
  # through the compositor's virtual keyboard instead.
  dconf.settings."org/freedesktop/ibus/engine/hangul" = {
    use-event-forwarding = false;
  };

  xdg.configFile."quickshell/panel".source = ./quickshell/panel;
  xdg.configFile."quickshell/lock".source = ./quickshell/lock;

  xdg.configFile."autostart/ibus-daemon.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=IBus
    Hidden=true
  '';

  xdg.configFile."foot/foot.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=11
    font-bold=JetBrainsMono Nerd Font:style=Bold:size=11
    font-italic=JetBrainsMono Nerd Font:style=Italic:size=11
    font-bold-italic=JetBrainsMono Nerd Font:style=Bold Italic:size=11
    pad=10x8
  '';

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    font=Adwaita Sans:size=12
    width=48
    lines=12
    horizontal-pad=18
    vertical-pad=14
    inner-pad=8

    [colors]
    background=11131aff
    text=cad3f5ff
    prompt=8aadf4ff
    placeholder=6e738dff
    input=cad3f5ff
    match=f5bde6ff
    selection=24273aff
    selection-text=cad3f5ff
    selection-match=f5bde6ff
    border=8aadf4ff

    [border]
    width=1
    radius=10
  '';

  xdg.configFile."mako/config".text = ''
    font=Adwaita Sans 11
    background-color=#11131aee
    text-color=#cad3f5ff
    border-color=#8aadf4ff
    border-size=1
    border-radius=10
    padding=12
    margin=12
    default-timeout=5000
  '';

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
    enable = true;
    name = "WhiteSur-cursors";
    size = 24;
    package = pkgs.whitesur-cursors;
    gtk.enable = true;
  };

  home.file.".wallpaper.png".source = ./wallpaper.png;
}

{ ... }:

{
  # Niri session (used on all hosts). Providing a config.kdl replaces niri's
  # built-in defaults, so all binds are spelled out. Mod+L stays as the lock
  # key, so column-right also gets Mod+Semicolon.
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                // fcitx5-hangul maps keysyms to jamo itself and its group
                // layout is "us", so keep the layout name "us" too: the
                // old "kr"/kr104 variant would make the compositor and
                // fcitx5 disagree (and turn the Hangul key into Alt_R).
                // These options keep the old Korean-key behaviour: right
                // Alt is Hangul, right Ctrl is Hanja.
                layout "us"
                options "korean:ralt_hangul,korean:rctrl_hanja"
            }
        }
    }

    cursor {
        xcursor-theme "WhiteSur-cursors"
        xcursor-size 24
    }

    environment {
        XMODIFIERS "@im=fcitx"
    }

    // fcitx5 speaks input-method-v2, so it is the IME for niri's text-input-v3
    // clients. -d detaches; the next login's spawn is a no-op if one is
    // already running. Everything else (bar, notifications, idle lock,
    // wallpaper, polkit agent, network applet) is Noctalia, started by its
    // systemd user service rather than here.
    spawn-at-startup "fcitx5" "-d"

    prefer-no-csd

    // Noctalia draws a blurred copy of the wallpaper into niri's overview
    // backdrop (see [backdrop] in programs.noctalia.settings).
    layer-rule {
        match namespace="^noctalia-backdrop"
        place-within-backdrop true
    }

    // Noctalia's settings window is a regular toplevel; float it instead of
    // tiling it into the current column.
    window-rule {
        match app-id="dev.noctalia.Noctalia"
        open-floating true
        default-column-width { fixed 1080; }
        default-window-height { fixed 920; }
    }

    // Lets Noctalia's notification actions and window activation work.
    debug {
        honor-xdg-activation-with-invalid-serial
    }

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

    // niri animates all of this by default, but the stock parameters are
    // critically damped and short enough to read as an instant jump. Same
    // animations, retuned for visible motion: the window open/close easing
    // gets a longer travel, and everything that moves geometry uses an
    // underdamped spring, so it settles with a little overshoot instead of
    // stopping dead. Damping stays under 1.0 because niri warns that
    // overdamped springs glitch. Animations not listed here
    // (config-notification, exit-confirmation, recent-windows) keep niri's
    // defaults.
    animations {
        window-open {
            duration-ms 220
            curve "ease-out-expo"
        }

        window-close {
            duration-ms 190
            curve "ease-out-quad"
        }

        window-movement {
            spring damping-ratio=0.9 stiffness=500 epsilon=0.0001
        }

        window-resize {
            spring damping-ratio=0.9 stiffness=500 epsilon=0.0001
        }

        horizontal-view-movement {
            spring damping-ratio=0.85 stiffness=600 epsilon=0.0001
        }

        workspace-switch {
            spring damping-ratio=0.85 stiffness=700 epsilon=0.0001
        }

        overview-open-close {
            spring damping-ratio=0.85 stiffness=500 epsilon=0.0001
        }

        screenshot-ui-open {
            duration-ms 250
            curve "ease-out-quad"
        }
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+Return { spawn "foot"; }
        Mod+D { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
        Mod+Shift+Return { spawn "luciole"; }
        Mod+L { spawn "noctalia" "msg" "session" "lock"; }
        Mod+Escape { spawn "noctalia" "msg" "panel-toggle" "session"; }
        Mod+S { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
        Mod+Shift+Comma { spawn "noctalia" "msg" "settings-toggle"; }

        // Hardware keys stay on wpctl/brightnessctl: they work with
        // allow-when-locked and from a TTY, and Noctalia's PipeWire and
        // backlight services drive its OSD from the resulting changes.
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "--min-value=1" "set" "+5%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "--min-value=1" "set" "5%-"; }

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
}

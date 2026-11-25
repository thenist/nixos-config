{ lib, pkgs, ... }:

{
  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "26.11";

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

      # Catppuccin matches the old shell's palette and the greeter scheme.
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";

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
        default.path = "${./wallpaper.png}";
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

      lockscreen.enabled = true;
    };
  };

  # Noctalia's own file manager, installed by the upstream flake input. The
  # built-in `luciole` template below writes ~/.config/luciole/colors.toml,
  # which Luciole reads live (its color_scheme defaults to "auto"). Layout and
  # behaviour preferences stay in Luciole's GUI-managed settings.toml.
  programs.luciole = {
    enable = true;
  };

  programs.vscode = {
    enable = true;
  };

  # GitHub identity (github.com/thenist, owner of this repo's origin).
  # Home-manager writes this to $XDG_CONFIG_HOME/git/config, which git reads
  # (XDG_CONFIG_HOME is unset in the session, so it resolves to
  # ~/.config/git/config). The imperative ~/.gitconfig that lived at the
  # classic path has been moved to ~/.gitconfig.backup: git gives that file
  # priority over the XDG one, so leaving it would silently shadow any later
  # edit here.
  programs.git = {
    enable = true;
    settings = {
      user.name = "thenist";
      user.email = "p717394@gmail.com";
    };
  };

  programs.vim = {
    enable = true;
    plugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "42header";
        version = "unstable-2026-05-13";
        src = pkgs.fetchFromGitHub {
          owner = "42Paris";
          repo = "42header";
          rev = "0b5698ad1c7cc6d43783419d97c8e6cf97088e64";
          hash = "sha256-xdH/SeGv1bfKMmJ9cHYd5V+ynFohzprnUC8eVer1VcI=";
        };
      })
    ];
    extraConfig = ''
      let g:user42 = 'sumpark'
      let g:mail42 = 'sumpark@student.42gyeongsan.kr'
    '';
  };

  # oh-my-zsh + powerlevel10k. oh-my-zsh resolves custom themes from
  # $ZSH_CUSTOM/themes/$ZSH_THEME.zsh-theme, and the nixpkgs powerlevel10k
  # package ships exactly share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme,
  # so its share/zsh doubles as ZSH_CUSTOM. Completion/compinit is left to
  # oh-my-zsh (common.nix disables the global /etc/zshrc compinit so it does
  # not run twice per shell).
  #
  # ~/.zshrc is a read-only store symlink, so the p10k wizard refuses to
  # append its two fragments to it ("readonly and not owned by the user").
  # They live here instead; mkBefore lands at the top of .zshrc, mkAfter at
  # the bottom, exactly where the wizard would have put them. The prompt
  # config itself is the wizard's output, copied verbatim to p10k.zsh: after
  # a fresh `p10k configure` run, copy ~/.p10k.zsh over it to persist.
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      custom = "${pkgs.zsh-powerlevel10k}/share/zsh";
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      (lib.mkAfter ''
        # To customize prompt, run `p10k configure` or edit p10k.zsh in nixos-config.
        source ${./p10k.zsh}
      '')
    ];
  };

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

  # Folders opened through xdg-open, FileManager1 or a portal go to Luciole
  # now that Thunar is gone. mimeApps is opt-in in home-manager.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "dev.noctalia.luciole.desktop";
  };

  # Noctalia's foot template writes the palette to
  # ~/.config/foot/themes/noctalia at runtime. The include has to be
  # declarative because home-manager owns foot.ini as a read-only store
  # symlink, which Noctalia's apply.sh cannot append to.
  xdg.configFile."foot/foot.ini".text = ''
    [main]
    include=~/.config/foot/themes/noctalia
    font=JetBrainsMono Nerd Font:size=11
    font-bold=JetBrainsMono Nerd Font:style=Bold:size=11
    font-italic=JetBrainsMono Nerd Font:style=Italic:size=11
    font-bold-italic=JetBrainsMono Nerd Font:style=Bold Italic:size=11
    pad=10x8
  '';

  gtk = {
    enable = true;

    # Sets gtk-application-prefer-dark-theme in the GTK 3/4 settings.ini and
    # org.gnome.desktop.interface color-scheme in dconf. Everything that reads
    # the XDG settings portal gets this too (libadwaita, Qt, Chromium/Electron),
    # which is why apps that ignore gtk-theme-name still render dark.
    colorScheme = "dark";

    # Noctalia's GTK templates (theme.templates above) layer its palette over
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

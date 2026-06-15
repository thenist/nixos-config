{ config, pkgs, ... }:

let
  ibusPackage = pkgs.ibus-with-plugins.override {
    plugins = with pkgs.ibus-engines; [ hangul ];
  };
  driftwmIbusStart = pkgs.writeShellScript "driftwm-ibus-start" ''
    export XMODIFIERS=@im=ibus
    ${pkgs.systemd}/bin/systemctl --user unset-environment GTK_IM_MODULE QT_IM_MODULE || true
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd XMODIFIERS
    exec ${ibusPackage}/libexec/ibus-ui-gtk3 --enable-wayland-im --exec-daemon --daemon-args "--xim --panel disable"
  '';
in
{
  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "26.05";

  programs.vscode = {
    enable = true;
  };

  xdg.configFile."driftwm/config.toml".text = ''
    autostart = [
      "${driftwmIbusStart}",
      "quickshell -p ~/.config/quickshell/panel/shell.qml",
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1",
      "nm-applet",
      "mako",
      "swayidle -w timeout 600 'quickshell -n -p ~/.config/quickshell/lock/shell.qml' before-sleep 'sh -c \"quickshell -n -d -p ~/.config/quickshell/lock/shell.qml; sleep 1\"'"
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
    name = "WhiteSur-cursors";
    size = 24;
    package = pkgs.whitesur-cursors;
    gtk.enable = true;
  };

  home.file.".wallpaper.png".source = ./wallpaper.png;
}

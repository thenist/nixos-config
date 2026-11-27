# Korean input: fcitx5 with the libhangul-based hangul engine (the same
# engine ibus-hangul wraps, so composition behaviour is unchanged). fcitx5
# implements both input-method-v1 and -v2, so it drives niri's text-input-v3
# clients directly, and it re-injects unhandled keys through the compositor's
# virtual keyboard instead of relying on forward_key_event, which is what the
# old ibus setup could not do on Wayland.
#
# waylandFrontend leaves GTK_IM_MODULE/QT_IM_MODULE unset so GTK 3/4 and
# Qt >= 6.8.2 use text-input-v3; XMODIFIERS is set for X11/XWayland apps.
# The niri keymap makes right Alt the Hangul key, so keep it as the toggle,
# as before, with Ctrl+Space as the fallback.

{ pkgs, ... }:

{
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      waylandFrontend = true;
      # fcitx5 dumps its own copy of the config into ~/.config/fcitx5 when it
      # exits, and that copy shadows /etc/xdg/fcitx5 (it is what turned the
      # toggle key into an empty value). Ignore the user copy so the settings
      # below stay authoritative.
      ignoreUserConfig = true;
      addons = with pkgs; [
        fcitx5-hangul
        qt6Packages.fcitx5-configtool
      ];
      settings = {
        # fcitx5 stores hotkey *lists* as indexed sub-keys, not as a
        # comma-separated string, so this has to render as
        #   [Hotkey/TriggerKeys]
        #   0=Hangul
        #   1=Control+space
        # to match fcitx5's own on-disk format.
        globalOptions."Hotkey/TriggerKeys" = {
          "0" = "Hangul";
          "1" = "Control+space";
        };
        # No popup on Korean/English switches. fcitx5's overlay message is
        # the "Show Input Method Information when switch input method" option;
        # ShowFirstInputMethodInformation only affects the inactive (English)
        # half and is moot while this is off.
        globalOptions.Behavior.ShowInputMethodInformation = false;
        # Default group: US layout plus the Hangul engine. Starting on
        # keyboard-us keeps a fresh session English until the toggle is hit.
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "hangul";
          "GroupOrder"."0" = "Default";
        };
      };
    };
  };
}

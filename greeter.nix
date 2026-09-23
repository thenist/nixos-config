# Quickshell greeter launched through greetd. The desktop session it starts
# after authentication is configured per host via the greeter.* options
# (niri.nix sets them for the niri hosts).

{ config, pkgs, lib, ... }:

let
  cfg = config.greeter;
  greeterConfig = import ./quickshell/with-i18n.nix {
    inherit pkgs;
    dir = ./quickshell/greeter;
  };
  quickshellGreeter = pkgs.writeShellScript "quickshell-greeter" ''
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export GREETER_SESSION_NAME=${lib.escapeShellArg cfg.sessionName}
    export GREETER_SESSION_CMD=${lib.escapeShellArg cfg.sessionCommand}
    # The greeter runs outside any user session, so it has no locale to inherit;
    # the i18n singleton reads LANG to pick the login screen's language.
    ${lib.optionalString (config.i18n.defaultLocale != null)
      "export LANG=${lib.escapeShellArg config.i18n.defaultLocale}"}
    exec ${pkgs.cage}/bin/cage -- ${pkgs.quickshell}/bin/quickshell -p /etc/quickshell/greeter/shell.qml
  '';
in
{
  options.greeter = {
    sessionName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the desktop session shown by the greeter.";
    };

    sessionCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command the greeter launches after a successful login.";
    };
  };

  config = {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${quickshellGreeter}";
        user = "greeter";
      };
    };

    environment.etc."quickshell/greeter".source = greeterConfig;
  };
}

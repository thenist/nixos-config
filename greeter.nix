# Quickshell greeter launched through greetd. The desktop session it starts
# after authentication is configured per host via the greeter.* options
# (driftwm.nix sets them for driftwm hosts; niri hosts set them themselves).

{ config, pkgs, lib, ... }:

let
  cfg = config.greeter;
  quickshellGreeter = pkgs.writeShellScript "quickshell-greeter" ''
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export GREETER_SESSION_NAME=${lib.escapeShellArg cfg.sessionName}
    export GREETER_SESSION_CMD=${lib.escapeShellArg cfg.sessionCommand}
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

    environment.etc."quickshell/greeter".source = ./quickshell/greeter;
  };
}

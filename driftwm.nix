# driftwm desktop session. Imported by hosts that run driftwm;
# the shared greeter lives in greeter.nix and portal setup in common.nix.

{ config, pkgs, inputs, ... }:

let
  driftwm = inputs.driftwm.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  greeter.sessionName = "driftwm";
  greeter.sessionCommand = "/run/current-system/sw/bin/driftwm-session";

  services.displayManager.sessionPackages = [ driftwm ];

  xdg.portal.configPackages = [ driftwm ];

  environment.systemPackages = [ driftwm ];
}

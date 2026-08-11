# driftwm desktop session. Imported by hosts that run driftwm;
# the shared greeter lives in greeter.nix and portal setup in common.nix.

{ config, pkgs, inputs, ... }:

let
  # driftwm's flake pins `libdisplay-info = "0.3.0"` in Cargo.toml, but the
  # followed nixpkgs now ships 0.4.0, which breaks the build. Pin the library
  # to the 0.3.0 package from nixpkgs for this build only.
  swapDisplayInfo = libd: if (libd.pname or "") == "libdisplay-info" then pkgs.libdisplay-info_0_3 else libd;

  driftwm = (inputs.driftwm.packages.${pkgs.stdenv.hostPlatform.system}.default).overrideAttrs (o: {
    buildInputs = map swapDisplayInfo o.buildInputs;
    # rebuild the runtime rpath so the binary resolves the pinned 0.3.0 lib
    postFixup = ''
      patchelf --add-rpath "${pkgs.lib.makeLibraryPath (map swapDisplayInfo o.buildInputs)}" $out/bin/driftwm
    '';
  });
in
{
  greeter.sessionName = "driftwm";
  greeter.sessionCommand = "/run/current-system/sw/bin/driftwm-session";

  services.displayManager.sessionPackages = [ driftwm ];

  xdg.portal.configPackages = [ driftwm ];

  environment.systemPackages = [ driftwm ];
}

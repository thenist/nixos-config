{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # KiCAD MCP server. Upstream flake builds the Rust binary against a
    # pinned toolchain and tracks its own nixpkgs, which we override so the
    # whole system shares one nixpkgs revision.
    konnect = {
      url = "github:mixelpixx/Konnect";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SolidCraft (parametric 3D CAD). Not in nixpkgs; upstream's flake packages
    # it with rustPlatform and wraps the GUI with the Wayland/EGL/dbus paths it
    # dlopens. Pinned nixpkgs is followed so it builds against this system's
    # rustc and store paths.
    solidcraft = {
      url = "github:tangency-labs/solidcraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixos-hardware, konnect, solidcraft, ... }: let
    # crates/smlib links the SMLib C API as a prebuilt archive published in the
    # tangency-labs/smlib release named by crates/smlib/SMLIB_REV, but its build
    # script only looks in the unpacked source tree
    # (target/smlib-<rev12>-prebuilt/<target>), which a sandbox never populates.
    # Pin the archive here, check it against SMLIB_PREBUILT, and unpack it where
    # the build script looks. Also carries the SHA-256 it demands in .sha256.
    # Every host here is x86_64-linux, hence the one target.
    smlibRev = "a18bbe523b9c7819f1a9da8c40a54c15f9936125";
    smlibTarget = "x86_64-unknown-linux-gnu";
    smlibSha256 = "e6a81eb955405c815e3efc05ac3ab6bd78df83e43d244a6b33bbb390a197c2db";
    tweakSolidcraft = pkgs:
      (solidcraft.packages.${pkgs.stdenv.hostPlatform.system}.solidcraft).overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.gnutar ];
        preBuild = ''
          smlibDir=target/smlib-${builtins.substring 0 12 smlibRev}-prebuilt/${smlibTarget}
          mkdir -p "$smlibDir"
          tar -xzf ${pkgs.fetchurl {
            url = "https://github.com/tangency-labs/smlib/releases/download/prebuilt-${smlibRev}/smlib-${smlibTarget}.tar.gz";
            hash = "sha256-5qgeuVVAXIFePvwFrDq2vXjfg+Q9JEprM7uzkKGXwts=";
          }} -C "$smlibDir" --strip-components=1
          echo ${smlibSha256} > "$smlibDir/.sha256"
        '';
        # egui has no font fallback of its own: crates/ui-egui searches hardcoded FHS
        # paths (/usr/share/fonts, ~/.local/share/fonts, ...) for a CJK and a Hangul
        # face, so on NixOS it finds none and a Korean UI or Hangul text is tofu.
        # SOLIDCRAFT_FONT_DIRS is the only hook, and it probes exact file names, so
        # alias the Noto CJK collection (which also draws Hangul) to the name it looks
        # for. Overridable by the user's own SOLIDCRAFT_FONT_DIRS.
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/solidcraft \
            --set-default SOLIDCRAFT_FONT_DIRS ${pkgs.runCommandLocal "solidcraft-fonts" { } ''
              mkdir -p $out
              ln -s ${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc \
                $out/NotoSansCJK-Regular.ttc
            ''}
        '';
      });
    extrasOverlay = _final: prev: {
      konnect = konnect.packages.${prev.stdenv.hostPlatform.system}.konnect;
      solidcraft = tweakSolidcraft prev;
    };
  in {
    packages.x86_64-linux.konnect = konnect.packages.x86_64-linux.konnect;
    packages.x86_64-linux.solidcraft = tweakSolidcraft nixpkgs.legacyPackages.x86_64-linux;

    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.tondemo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./common.nix
        ./niri.nix
        ./hosts/tondemo/configuration.nix
        ./hosts/tondemo/hardware-configuration.nix
        ./users/thenist/user.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-t480
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ extrasOverlay ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.thenist = import ./users/thenist/home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
    nixosConfigurations.wonderz = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./common.nix
        ./niri.nix
        ./hosts/wonderz/configuration.nix
        ./hosts/wonderz/hardware-configuration.nix
        ./users/thenist/user.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ extrasOverlay ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.thenist = import ./users/thenist/home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
    nixosConfigurations.raputa = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./common.nix
        ./niri.nix
        ./hosts/raputa/configuration.nix
        ./hosts/raputa/hardware-configuration.nix
        ./users/thenist/user.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ extrasOverlay ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.thenist = import ./users/thenist/home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}

{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SolidCraft (parametric 3D CAD). Not in nixpkgs; upstream's flake packages
    # it with rustPlatform and wraps the GUI with the Wayland/EGL/dbus paths it
    # dlopens. Follow upstream's `release` branch rather than its default branch
    # so updates land as tested releases instead of in-progress development
    # commits. Pinned nixpkgs is followed so it builds against this system's
    # rustc and store paths.
    solidcraft = {
      url = "github:tangency-labs/solidcraft/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Luciole, the Noctalia project's file manager. It is not in nixpkgs, so
    # this input carries upstream's own nixpkgs pin and toolchain.
    luciole = {
      url = "github:noctalia-dev/luciole";
    };
  };

  outputs = { nixpkgs, home-manager, nixos-hardware, solidcraft, luciole, ... }: let
    tweakSolidcraft = pkgs:
      (solidcraft.packages.${pkgs.stdenv.hostPlatform.system}.solidcraft).overrideAttrs (old: {
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
      solidcraft = tweakSolidcraft prev;
      # DSH profile plugins. home.nix's activation links each store copy into
      # the profiles that mount it, so nothing is fetched at activation time.
      moeseek = prev.callPackage ./packages/moeseek.nix { };
      dsh-korean-locale = prev.callPackage ./packages/dsh-korean-locale.nix { };
      dsh-archive-manager = prev.callPackage ./packages/dsh-archive-manager.nix { };
      dsh-genui = prev.callPackage ./packages/dsh-genui.nix { };
      dsh-wallet = prev.callPackage ./packages/dsh-wallet.nix { };
    };
  in {
    packages.x86_64-linux.solidcraft = tweakSolidcraft nixpkgs.legacyPackages.x86_64-linux;

    # Build with `nix build .#moeseek`, `nix build .#dsh-korean-locale`,
    # `nix build .#dsh-archive-manager`, `nix build .#dsh-genui`, or
    # `nix build .#dsh-wallet`. Kept as outputs as well as overlays so each
    # bundle can be built and tested without evaluating a host.
    packages.x86_64-linux.moeseek =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/moeseek.nix { };
    packages.x86_64-linux.dsh-korean-locale =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/dsh-korean-locale.nix { };
    packages.x86_64-linux.dsh-archive-manager =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/dsh-archive-manager.nix { };
    packages.x86_64-linux.dsh-genui =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/dsh-genui.nix { };
    packages.x86_64-linux.dsh-wallet =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/dsh-wallet.nix { };

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
            sharedModules = [ luciole.homeModules.default ];
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
            sharedModules = [ luciole.homeModules.default ];
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
            sharedModules = [ luciole.homeModules.default ];
          };
        }
      ];
    };
  };
}

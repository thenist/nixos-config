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
  };

  outputs = { nixpkgs, home-manager, nixos-hardware, konnect, ... }: let
    konnectOverlay = _final: prev: {
      konnect = konnect.packages.${prev.stdenv.hostPlatform.system}.konnect;
    };
  in {
    packages.x86_64-linux.konnect = konnect.packages.x86_64-linux.konnect;

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
          nixpkgs.overlays = [ konnectOverlay ];
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
          nixpkgs.overlays = [ konnectOverlay ];
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
          nixpkgs.overlays = [ konnectOverlay ];
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

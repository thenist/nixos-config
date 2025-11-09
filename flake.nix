{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.tondemo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./common.nix
        ./hosts/tondemo/configuration.nix
        ./hosts/tondemo/hardware-configuration.nix
        ./users/thenist/user.nix
        home-manager.nixosModules.home-manager
        {
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
        ./hosts/wonderz/configuration.nix
        ./hosts/wonderz/hardware-configuration.nix
        ./users/thenist/user.nix
        home-manager.nixosModules.home-manager
        {
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

{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

	 home-manager = {
       url = "github:nix-community/home-manager";
       inputs.nixpkgs.follows = "nixpkgs";
     };
     # Stylix: theming framework for NixOS + HM
         stylix = {
           url = "github:nix-community/stylix/release-25.05";
           inputs.nixpkgs.follows = "nixpkgs"; # keep pkgs in sync
         };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/desktop/configuration.nix
         inputs.home-manager.nixosModules.default
      ];
    };
  };
}

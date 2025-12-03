{
  description = "Nixos config flake";

  inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
};

  outputs = { self, nixpkgs, ... }@inputs: {
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/desktop/configuration.nix
      ];
    };
  };
}

{
  description = "An example NixOS configuration";

  inputs.nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      mysystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
         (import ./configuration.nix)
       ];
      };
    };
  };
}


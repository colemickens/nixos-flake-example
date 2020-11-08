
{
  description = "An example NixOS configuration";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    nur = { url = "github:nix-community/NUR"; };
  };

  outputs = inputs:
    /* ignore:: */ let ignoreme = ({config,lib,...}: with lib; { system.nixos.revision = mkForce null; system.nixos.versionSuffix = mkForce "pre-git"; }); in
  {
    nixosConfigurations = {

      mysystem = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import ./configuration.nix)

          /* ignore */ ignoreme # ignore this; don't include it; it is a small helper for this example
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}


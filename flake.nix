{
  description = "exec-dpdk";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    nixvirt = {
      url = "github:antholeole/NixVirt/f7c18876bd52cbb49f5c1e8971caec2354f0f44d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    nixvirt,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.treefmt-nix.flakeModule

        ./nix/treefmt.nix
        # ./nix/dpdk-img.nix
        ./nix/shell.nix
        ./nix/external.nix
        ./nix/nixvirt.nix
      ];

      flake = {};
      systems = nixpkgs.lib.systems.flakeExposed;
    };
}

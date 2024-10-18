{
  description = "exec-dpdk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
        ./nix/qcow-config.nix
        ./nix/shell.nix
        ./nix/virt-scripts.nix
      ];

      flake = {};
      systems = nixpkgs.lib.systems.flakeExposed;
    };
}

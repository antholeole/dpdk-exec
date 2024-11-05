{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        clang-format.enable = true;
      };
    };
  };
}

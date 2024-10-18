# all the external packages that we build;
# mostly just exposed here for ease of testing, so we can
# nix build them directly to make sure they build.
{inputs, ...}: {
  perSystem = {pkgs, ...}: {
  };
}

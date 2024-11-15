{...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: let
    attrs = (import ./vm-config/attrs.nix) pkgs;
  in {
    devShells.default = pkgs.mkShell {
      packages = with pkgs;
        [
          qemu_kvm
          numactl
        ]
        ++ attrs.devPkgs;

      shellHook = ''
        export LIBVIRT_DEFAULT_URI="qemu:///system"
      '';
    };
  };
}

{...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: let
  in {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        meson
        ninja
        dpdk # 23.11
        pkg-config

        qemu_kvm
        libvirt
        numactl

        # config.packages.dpdk-vm-run
      ];
    };
  };
}

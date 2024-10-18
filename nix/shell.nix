{...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: let
    hugepageSize = 2048;
    hugepageNum = 512;
    setup-dpdk = pkgs.writeShellScriptBin "setup-dpdk" ''
      set -euo pipefail

      # setup the VM drive file
      mkdir -p ~/.local/share/DPDKVMS/
      touch ~/.local/share/DPDKVMS/dpdk-vm1

      # TODO: set nr hugepages to the correct value
      # if this doesn't work (perhaps a large amount of memory is being used, making us unable to reserve it), try adding `vm.nr_hugepages = ${toString hugepageNum}` to /etc/sysctl.conf
      # echo ${toString hugepageNum} > /sys/devices/system/node/node0/hugepages/hugepages-${toString hugepageSize}kB/nr_hugepages

      # TODO: dynamically populate these variables
      sudo ${pkgs.dpdk}/bin/dpdk-hugepages.py -p ${toString hugepageSize}K --setup ${toString (hugepageNum * hugepageSize)}K
      sudo ${pkgs.dpdk}/bin/dpdk-hugepages.py -s
    '';
  in {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        setup-dpdk

        cmake
        dpdk # 23.11
        pkg-config

        qemu_kvm
        libvirt

        # config.packages.dpdk-vm-run
      ];
    };
  };
}

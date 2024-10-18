{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }:
    with pkgs; let
    in rec {
      packages.dpdk-vm-run = let
        mkScript = name: drvs: script:
          symlinkJoin {
            inherit name;
            paths = drvs ++ [(pkgs.writeShellScriptBin name script)];
          };

        rocky-qcow2 = pkgs.fetchurl {
          url = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-EC2-Base-9.4-20240509.0.x86_64.qcow2";
          hash = "sha256-xdgxBHZ5QP3SPYpwmKg4vzN/y+Qomc6+XKkHJnJW4w0=";
        };

        switch = "br0";

        # https://www.linux-kvm.org/page/Networking
        qemu-ifup = mkScript "qemu-ifup" [busybox] ''
          set -x

          if [ -n "$1" ]; then
                  sudo ${iproute2}/bin/ip link add br0 type bridge ; sudo ${busybox}/bin/ifconfig br0 up
                  sudo ${iproute2}/bin/ip tuntap add $1 mode tap group netdev
                  sudo ${iproute2}/bin/ip link set $1 up
                  sleep 0
                  sudo ${iproute2}/bin/ip link set $1 master ${switch}
                  exit 0
          else
                  echo "Error: no interface specified"
                  exit 1
          fi
        '';

        qemu-ifdown = mkScript "qemu-ifdown" [busybox] ''
          set -x

          if [ -n "$1" ]; then
          	sudo ${busybox}/bin/brctl delif ${switch} $1
          	sudo ${iproute2}/bin/ip link set $1 down
          	exit 0
          else
          	echo "Error: no interface specified"
          	exit 1
          fi
        '';

        genMAC = mkScript "genmac" [busybox] ''
          printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))
        '';
      in
        mkScript "dpdk-vm-run" [qemu_kvm] ''
          set -euo pipefail

          macaddress="$(${genMAC}/bin/genmac)"

          qemu-system-x86_64 -enable-kvm -cpu host -m 2048 -smp 2 -mem-path /dev/hugepages \
            -mem-prealloc \
            -drive file=${rocky-qcow2},readonly=on \
            -device e1000,netdev=net0,mac=$macaddress \
            -netdev tap,id=net0,script=${qemu-ifup}/bin/qemu-ifup,downscript=${qemu-ifdown}/bin/qemu-ifdown \
            -device pci-assign,host=04:10.1
        '';
    };
}

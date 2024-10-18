{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    lib,
    config,
    ...
  }: let
    libvirt-conf = with inputs;
      import ./vm-config/libvirt-xml.nix {
        inherit pkgs nixvirt lib;
      };
  in {
    packages = {
      setup-hugepages = let
        hugepageSize = 2048;
        hugepageNum = 1024;
      in
        pkgs.writeShellScriptBin "setup-hugepages" ''
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

      testpmd = pkgs.writeShellScriptBin "testpmd" ''
        sudo ${pkgs.dpdk}/bin/dpdk-testpmd -l 0,2 --socket-mem=512 -n 3 \
            --vdev 'net_vhost0,iface=/tmp/vhost-user1' \
            --vdev 'net_vhost1,iface=/tmp/vhost-user2' -- \
            --portmask=f -i --rxq=1 --txq=1 \
            --nb-cores=1 --forward-mode=io
      '';

      runvirt = let
        virtdeclare = inputs.nixvirt.apps.${system}.virtdeclare;
        qemu-connect = "qemu:///system";
        mk-command = type: xml-path: "${virtdeclare.program} --define ${xml-path} --state $1 --connect ${qemu-connect} --type ${type}";

        # do this here because it needs to happen before we start the VM but after we start testpmd
        mk-chmod-sock = idx: let sockPath = (builtins.elemAt libvirt-conf.dpdk-domain.devices.interface idx).source.path; in "sudo chmod 666 ${sockPath}";
      in
        with virtdeclare;
          pkgs.writeShellScriptBin "runvirt" ''
            # copy the qcow into a global, runnable place.
            rm ${libvirt-conf.required-qcow-path}
            cp ${config.packages.nixos-qcow2}/nixos.qcow2 ${libvirt-conf.required-qcow-path}
            sudo chmod 777 ${libvirt-conf.required-qcow-path} # TODO: figure out a better way to do this

            ${mk-chmod-sock 0}
            ${mk-chmod-sock 1}

            ${mk-command "domain" "${libvirt-conf.dpdk-domain-xml}"}
            ${mk-command "network" "${libvirt-conf.dpdk-network-xml}"}
          '';
    };
  };
}

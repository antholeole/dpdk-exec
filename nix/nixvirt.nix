{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }:
    with inputs.nixvirt.lib; let
      dpdk-network = network.writeXML {
        name = "dpdk-network";
        uuid = "c4acfd00-4597-41c7-a48e-e2302234fa89";
        bridge = {name = "br0";};
        mac = {address = "52:54:00:02:77:4b";};
      };

      dpdk-domain =
        (domain.templates.linux {
          name = "Penguin";
          uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
          memory = {
            count = 6;
            unit = "GiB";
          };
          storage_vol = {
            pool = "MyPool";
            volume = "Penguin.qcow2";
          };
          devices = [
            {
              type = "vhostuser";
              mac = "something";
            }
          ];

          bridge = with dpdk-network.bridge; {inherit name;};
        })
        // {
          vcpu = {
            placement = "static";
            count = 2;
          };
          memoryBacking = {
            locked = {};
            hugepages = {
              page = {
                size = 2048;
                unit = "KiB";
                nodeset = "0";
              };
            };
          };

          numatune = {
            memory = {
              mode = "strict";
              nodeset = "0";
            };
          };

          cpu = {
            mode = "host-passthrough";
            check = "none";
            topology = {
              sockets = 1;
              cores = 2;
              threads = 1;
            };
            numa.cell = {
              id = "0";
              cpus = "0-1";
              memory = 3145728;
              unit = "KiB";
              memAccess = "shared";
            };
          };

          devices = {
            emulator = "/usr/bin/qemu-system-x86_64";
            interface = let
              vhostUser = idx: {
                type = "vhostuser";
                model = {type = "virtio";};
                mac = {address = "56:48:4f:53:54:0${toString idx}";};
                source = {
                  type = "unix";
                  path = "/tmp/vhost-user${toString idx}";
                  mode = "client";
                };
                # this doesn't work
              };
            in [
              (vhostUser 1)
              (vhostUser 2)
            ];
          };
        };

      dpdk-domain-xml = domain.writeXML dpdk-domain;
    in {
      packages.testpmd = pkgs.writeShellScriptBin "testpmd" ''
        sudo ${pkgs.dpdk}/bin/dpdk-testpmd -l 0,2 --socket-mem=1024 -n 3 \
            --vdev 'net_vhost0,iface=/tmp/vhost-user1' \
            --vdev 'net_vhost1,iface=/tmp/vhost-user2' -- \
            --portmask=f -i --rxq=1 --txq=1 \
            --nb-cores=1 --forward-mode=io
      '';

      packages.runvirt = let
        virtdeclare = inputs.nixvirt.apps.${system}.virtdeclare;
        qemu-connect = "qemu:///system";
        mk-command = type: xml-path: "${virtdeclare.program} --define ${xml-path} --state $1 --connect ${qemu-connect} --type ${type}";

        # do this here because it needs to happen before we start the VM but after we start testpmd
        mk-chmod-sock = idx: let sockPath = (builtins.elemAt dpdk-domain.devices.interface idx).source.path; in "sudo chmod 666 ${sockPath}";
      in
        with virtdeclare;
          pkgs.writeShellScriptBin "runvirt" ''
            ${mk-chmod-sock 0}
            ${mk-chmod-sock 1}
            ${mk-command "domain" "${dpdk-domain-xml}"}
            ${mk-command "network" "${dpdk-network}"}
          '';
    };
}

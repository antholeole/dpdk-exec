{
  nixvirt,
  pkgs,
  lib,
  ...
}:
with nixvirt.lib; let
  required-qcow-path = "/tmp/dpdk-nixos.qcow2";

  dpdk-network = {
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
        count = 1;
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
          cores = 1;
          threads = 1;
        };
        numa.cell = {
          id = "0";
          cpus = "0";
          memory = 100;
          unit = "MiB";
          memAccess = "shared";
        };
      };

      devices = {
        emulator = "/usr/bin/qemu-system-x86_64";

        disk = {
          type = "file";
          device = "disk";

          driver = {
            type = "qcow2";
            cache = "none";
          };

          target = {
            dev = "vda";
            bus = "virtio";
          };

          source = {
            file = required-qcow-path;
          };
        };

        serial = {
          target = {
            port = 0;
          };
        };

        console = {
          type = "pty";
          target = {
            type = "serial";
            port = 0;
          };
        };

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
in {
  # these are the nix objects...
  inherit dpdk-network dpdk-domain required-qcow-path;

  # these are the raw XML paths.
  dpdk-domain-xml = domain.writeXML dpdk-domain;
  dpdk-network-xml = network.writeXML dpdk-network;
}

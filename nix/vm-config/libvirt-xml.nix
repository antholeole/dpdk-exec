{
  nixvirt,
  pkgs,
  lib,
  ...
}:
with nixvirt.lib; let
  required-qcow-path = "/tmp/dpdk-nixos.qcow2";

  guest-mac = "02:ca:fe:fa:ce:05"; # Default management MAC address
  guest-ip = "192.168.200.10";

  dpdk-network = {
    name = "dpdk-network";
    uuid = "c4acfd00-4597-41c7-a48e-e2302234fa89";
    bridge.name = "br0";
    mac.address = "52:54:00:02:77:4b";
    forward = {};
    dns = {
      host = {
        ip = guest-ip;
        hostname = "dpdk-vm.testvirtio.com";
      };
    };
    ip = {
      address = "192.168.200.1";
      netmask = "255.255.255.0";
      dhcp = {
        host = {
          mac = guest-mac;
          ip = guest-ip;
        };
        range = {
          start = "192.168.200.2";
          end = "192.168.200.254";
        };
      };
    };
  };

  dpdk-domain =
    (domain.templates.linux {
      name = "Penguin";
      uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
      memory = {
        count = 1;
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
    // (let
      tty-serial-port = 1; # use 0 to "void" sysmessages
    in {
      vcpu = {
        placement = "static";
        count = 3;
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
          cores = 3;
          threads = 1;
        };
        numa.cell = {
          id = "0";
          cpus = "0-2";
          memory = 512;
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
            port = tty-serial-port;
          };
        };

        console = {
          type = "pty";
          target = {
            type = "serial";
            port = tty-serial-port;
          };
        };

        interface = let
          vhostUser = idx: {
            type = "vhostuser";
            model = {type = "virtio";};
            mac = {address = "56:48:4f:53:54:0${toString idx}";};
            driver = {
              name = "vhost";
              rx_queue_size = 256;
            };
            address = {
              type = "pci";
              domain = 0;
              bus = 10 + idx;
              slot = 0;
              function = 0;
            };
            source = {
              type = "unix";
              path = "/tmp/vhost-user${toString idx}";
              mode = "client";
            };
          };
        in [
          (vhostUser 1)
          (vhostUser 2)
          {
            type = "network";
            target.dev = "vnet0";
            model.type = "virtio";
            alias.name = "net0";
            mac.address = guest-mac;
            address = {
              type = "pci";
              domain = 0;
              bus = 0;
              slot = 0;
              function = 0;
            };
            source = with dpdk-network; {
              network = name;
              bridge = bridge.name;
            };
          }
        ];
      };
    });
in {
  # these are the nix objects...
  inherit dpdk-network dpdk-domain required-qcow-path;

  # these are the raw XML paths.
  dpdk-domain-xml = domain.writeXML dpdk-domain;
  dpdk-network-xml = network.writeXML dpdk-network;
}

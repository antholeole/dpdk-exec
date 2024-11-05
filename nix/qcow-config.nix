{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.nixos-qcow2 = let
      attrs = (import ./vm-config/attrs.nix) pkgs;
      configuration = {...}: let
        dpdk-user-pwd = "hunter2";
      in {
        system.stateVersion = "24.11";

        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
          autoResize = true;
        };

        boot = {
          kernelPackages = pkgs.linuxPackages_latest;
          kernelParams = [
            "console=ttyS1"
            "console=ttyS0,115200"
            "transparent_hugepage=never"
            "hugepagesz=2MB"
            "hugepages=128"
            "vfio.enable_unsafe_noiommu_mode=1"
          ];
          kernelModules = [
            "vfio_pci"
            "vfio"
          ];

          # happy building!
          kernelPatches = [
            {
              name = "CONFIG_VFIO_NOIOMMU";
              patch = null;
              extraConfig = ''
                VFIO_NOIOMMU y
              '';
            }
          ];
          loader = {
            grub = {
              enable = true;
              device = "/dev/vda";

              extraConfig = ''
                serial --unit=1 --speed=115200 --word=8 --parity=no --stop=1

                terminal_input --append serial
                terminal_output --append serial

                VFIO_NOIOMMU y
              '';
            };
          };
        };

        systemd.services = let
          mk-serial-tty = idx: {
            "serial-getty@ttyS${toString idx}" = {
              enable = true;
              wantedBy = ["getty.target"];
              serviceConfig.Restart = "always";
            };
          };
        in
          {
          }
          // (mk-serial-tty 0)
          // (mk-serial-tty 1);

        environment.systemPackages = with pkgs;
          attrs.devPkgs
          ++ [
            kakoune
            bash

            # temp
            lsof
          ];

        networking = {
          hostName = "dpdk-vm";
          useDHCP = false;
          useNetworkd = false;
          enableIPv6 = false;
          interfaces.enp1s0.useDHCP = true;
        };

        services = {
          openssh = {
            enable = true;
            settings.PasswordAuthentication = true;
          };
        };

        users.users.dpdk-user = {
          isNormalUser = true;
          password = dpdk-user-pwd;
          extraGroups = ["wheel"];
        };
      };
    in
      inputs.nixos-generators.nixosGenerate {
        inherit system;
        format = "qcow";
        modules = [configuration];
      };
  };
}

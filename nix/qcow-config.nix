{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.nixos-qcow2 = let
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
            "console=ttyS0,115200"
            "console=tty1"
          ];
          loader = {
            grub = {
              enable = true;
              device = "/dev/vda";

              extraConfig = ''
                serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
                terminal_input --append serial
                terminal_output --append serial
              '';
            };
          };
        };

        systemd.services."serial-getty@ttyS0" = {
          enable = true;
          wantedBy = ["getty.target"];
          serviceConfig.Restart = "always";
        };

        environment.systemPackages = with pkgs; [
          kakoune
          bash
        ];

        networking = {
          hostName = "dpdk-vm";
          useDHCP = false;
          useNetworkd = false;
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

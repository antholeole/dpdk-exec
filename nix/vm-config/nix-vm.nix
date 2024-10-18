{
  pkgs,
  lib,
  ...
}:
with lib; let
  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot.growPartition = true;
    boot.kernelParams = ["console=ttyS0"];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    users.extraUsers = {
      dpdk-user = {
        password = "hunter2";
      };
    };

    users.extraUsers.root.password = "";
  };
in {
  nixos-qcow2 = pkgs.nixos. {
    inherit lib config pkgs;
    # TODO do i have to re-download pkgs?
    format = "qcow2";
    configFile =
      pkgs.writeText "configuration.nix"
      ''
        {
          imports = [ <./machine-config.nix> ];
        }
      '';
  };
}

pkgs: {
  devPkgs = with pkgs; [
    dpdk
    ninja
    libvirt
    cmake
    pkg-config
  ];
}

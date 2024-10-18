# dpdk-exec

P2300 over DPDK 

## Bootstrap

1. `nix run .#setup-hugepages`
1. begin the dpdk testpmd command with `nix run .#test-pmd` (needed to create the fake NIC sockets)
1. start the VM with `nix run .#runvirt --  active`


### Hugepages 

you need to have hugepages setup. 
TODO: instructions for hugepages
TODO: hard-coded 2048 huge-pages should allow 1G

### libvert

you must have `libvertd` service running:

```
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system

# add youself to the required groups
sudo usermod -aG libvirt-qemu $(whoami)
sudo usermod -aG libvirt $(whoami)
```

now, to start the environment (a network as well as a domain) run the following:

```
nix run .#runvirt --  active
```

and to stop, run

```
nix run .#runvirt --  inactive
```

## Useful development links

libvert tutorial: https://www.redhat.com/en/blog/hands-vhost-user-warm-welcome-dpdk

nixos qcow: https://tarnbarford.net/journal/building-nixos-qcow2-images-with-flakes/

### debug libvert

- `nix build .#runvirt && cat -p result/bin/runvirt | tail -3 | head -n1 | awk '{print $3}' | xargs -n1 cat` prints the libvert domain config

## TODO

- support dpdk secondary process (https://doc.dpdk.org/guides-23.11/linux_gsg/sys_reqs.html#running-dpdk-applications)
- add testpmd script:
```
sudo (which dpdk-testpmd) -l 0,2,3,4,5 --socket-mem=1024 -n 4 \
    --vdev 'net_vhost0,iface=/tmp/vhost-user1' \
    --vdev 'net_vhost1,iface=/tmp/vhost-user2' -- \
    --portmask=f -i --rxq=1 --txq=1 \
    --nb-cores=4 --forward-mode=io
```
# GNS3 Proxmox appliance

The `gns3_proxmox_defconfig` target builds an x86_64 BIOS disk image for a
Proxmox q35 VM. Linux and the internal toolchain headers are both pinned to
7.1.4. Buildroot obtains the headers from the selected kernel source through
`BR2_KERNEL_HEADERS_AS_KERNEL`; the `7.0.x or later` series selector is
Buildroot 2026.05.1's compatibility classification for 7.1 and newer kernels.

From the repository root, rebuild from a clean state with:

```sh
# Required only when starting from an unpatched Buildroot 2026.05.1 tree.
patch -d buildroot -p1 < \
  br2-external/board/gns3/buildroot-patches/0001-libvirt-do-not-force-cgroupfs-mount.patch
make -C buildroot distclean
make -C buildroot \
  BR2_EXTERNAL="$PWD/br2-external" \
  gns3_proxmox_defconfig
make -C buildroot \
  BR2_EXTERNAL="$PWD/br2-external" \
  -j4
```

The resulting Proxmox disk and kernel are
`buildroot/output/images/disk.img` and
`buildroot/output/images/bzImage`. The separately attachable templates disk is
`buildroot/output/images/gns3-templates.img`. Check the selected version with:

```sh
make -C buildroot \
  BR2_EXTERNAL="$PWD/br2-external" \
  linux-show-version
```

The kernel archive is checksum-verified for both the runtime kernel and
toolchain-header packages by the hash files below `board/gns3/patches`.
Downloads therefore fail closed if the archive does not match the pinned
Linux 7.1.4 release.

## Root filesystem profile

This appliance is optimized for an x86 Proxmox host. QEMU system emulation is
limited to x86_64 and i386; KVM and TCG remain enabled. Firmware and kernel
drivers for physical Wi-Fi, physical Ethernet adapters, audio hardware and
other non-VM devices are intentionally omitted. The kernel retains the q35,
VirtIO SCSI, VirtIO networking, console, nested KVM, container, bridge,
namespace, cgroup v2, nftables and ext4 features required by the appliance.
The post-build step also removes QEMU firmware for non-x86 targets while
retaining the x86 SeaBIOS, UEFI, VGA, NIC and boot ROM resources.

The system filesystem is 1 GiB. GNS3 images and user projects should be kept
on separate data disks rather than consuming this filesystem.

The BIOS disk has the fixed MBR signature `0x474e5333`, and GRUB selects its
root partition as `PARTUUID=474e5333-01`. It does not depend on whether
Proxmox enumerates the system disk as `/dev/sda`, `/dev/sdb`, or another SCSI
device when the templates and projects disks are attached.

## GNS3 NAT network

The image starts the modular `virtnetworkd` daemon through
`S58libvirt-network`, before Docker and GNS3. The service explicitly defines,
autostarts and starts the `default` network, then verifies that `virbr0`
exists. It creates `virbr0` at `192.168.122.1/24`, provides DHCP addresses
from `192.168.122.2` through `192.168.122.254`, and performs IPv4 NAT through
the outer VM's uplink. IPv4 forwarding is enabled by
`/etc/sysctl.d/90-gns3-libvirt.conf`.

The `dnsmasq` executable remains installed for `virtnetworkd`, but its
standalone Buildroot init service is removed to avoid DNS and DHCP socket
conflicts with libvirt's private dnsmasq instance.

Libvirt 7.10 records `/sbin/iptables`, `/sbin/ip6tables` and
`/sbin/ebtables` as absolute firewall-tool paths during configuration, while
Buildroot installs the selected iptables-nft tools under `/usr/sbin` in this
non-merged-`/usr` image. The post-build hook creates only those three
compatibility links so libvirt can initialize its direct firewall backend.

The project libvirt compatibility patch sets dnsmasq's target path to
`/usr/sbin/dnsmasq`. Without it, Meson's cross-build probe records a bare
`dnsmasq` command when the build host lacks that program, but libvirt later
passes the value directly to `stat()` without performing a PATH lookup.

The `S12qemu-guest-agent` BusyBox init service starts `qemu-ga` on the
Proxmox VirtIO serial channel `/dev/virtio-ports/org.qemu.guest_agent.0`.
Enable QEMU Guest Agent in the Proxmox VM options so that this channel exists.

The libvirt QEMU driver is intentionally disabled: GNS3 launches its QEMU
nodes directly and uses libvirt only to provide the NAT bridge. At runtime,
verify the network with:

```sh
/etc/init.d/S58libvirt-network status
pidof virtnetworkd
virsh -c network:///system net-list --all
ip address show virbr0
cat /proc/sys/net/ipv4/ip_forward
```

Buildroot 2026.05.1's libvirt Kconfig normally forces the legacy
`cgroupfs-mount` package for BusyBox-init systems. That conflicts with
Docker Engine and is unnecessary for this network-only libvirt deployment
on cgroup v2. The documented compatibility patch removes only that forced
selection; it does not alter libvirt source or disable dependency checks.

## Three-drive layout

Use three VirtIO SCSI disks and label their ext4 filesystems as follows:

| Filesystem label | Purpose | Mount point |
| --- | --- | --- |
| `GNS3_SYSTEM` | Buildroot and installed applications | `/` |
| `GNS3_TEMPLATES` | Images, appliances, symbols and shared configuration | `/var/lib/gns3/library` |
| `GNS3_PROJECTS` | User projects | `/var/lib/gns3/projects` |

The `S55gns3-storage` service locates data disks by filesystem label, so it
does not depend on `/dev/sdX` enumeration order. It mounts existing
filesystems but never partitions or formats a disk. The service creates the
required GNS3 subdirectories after mounting and GNS3 starts later as the
unprivileged `gns3` user.

The templates disk is mandatory because Docker stores its image layers there.
Docker refuses to start if `GNS3_TEMPLATES` is not mounted, preventing a large
container image from filling the system filesystem. A missing projects disk
continues to fall back to system-disk storage for initial testing only.

The build generates two data-disk artifacts: a sparse 6 GiB ext4
`gns3-templates.img` and an empty sparse 30 GiB ext4
`gns3-projects.img`. The projects image is labeled `GNS3_PROJECTS` and is
mounted automatically at `/var/lib/gns3/projects`; its larger virtual size
allows room for student projects, writable QEMU overlays and packet captures
without consuming 30 GiB on the build host while it remains empty.

The templates image is populated from
`inputs/chr-7.19.4.img.zip`. The build verifies the archive SHA-256
`e77f0d73a9c7841918debf4e9e1372f457274d58901b11463551056d9beaccf1`
and the extracted CHR image SHA-256
`bb2435e35376d891590d5219e3d3ea9e3feac05a5fe415181388327dd8aeb2f9`.
It contains MikroTik CHR 7.19.4 under `images/QEMU`, a matching appliance
definition, and a preconfigured QEMU template in `gns3_controller.conf`.
MikroTik RouterOS CHR remains subject to MikroTik's licensing terms.

The same disk also contains the supplied Alpine Linux Virt 3.22.1 QCOW2
image. Its SHA-256 is
`a049b4da77a2c723cc4fcb57e985e50cc6a5281a4ba012a65a2d0f0c69569e45`.
The seeded Alpine template uses one vCPU, 128 MiB RAM, a VirtIO disk, one
VirtIO network interface and a Telnet console.

The prepared Arista cEOS 4.29.3M Docker archive is also included. Its
SHA-256 is
`acf633e4bade9d22a6f1a426666401009cb618a255752f2c0389fd90a6f54c02`.
It was prepared from the supplied archive with SHA-256
`d35da1459a4b061fce3d6789e21bae0ae6b89114c4168cd7778bb41c1859ece9`.
The prepared image removes the tty1 getty link, uses `/sbin/init`, declares
`/mnt/flash` as a persistent volume and provides both `ceosimage:4.29.3M`
and `ceosimage:GNS3`. `S68ceos-image` verifies and loads it after Docker
starts and before GNS3 starts. Arista cEOS licensing terms apply.

Import `gns3-templates.img` into Proxmox as the second VirtIO SCSI disk. It
contains an ext4 filesystem directly, without a partition table, and is
labeled `GNS3_TEMPLATES` for automatic discovery.

Import `gns3-projects.img` as the third VirtIO SCSI disk. It likewise contains
an ext4 filesystem directly, is labeled `GNS3_PROJECTS`, and must not be
shared concurrently by multiple running appliance VMs. Proxmox storage may
allocate its full virtual capacity depending on the selected storage format
and provisioning mode.

To prepare new, empty data partitions, identify the exact target devices
first, then format them explicitly:

```sh
mkfs.ext4 -L GNS3_TEMPLATES /dev/your-template-partition
mkfs.ext4 -L GNS3_PROJECTS /dev/your-project-partition
/etc/init.d/S55gns3-storage restart
/etc/init.d/S55gns3-storage status
```

Formatting destroys existing data on the selected partitions. Never copy
these example device placeholders without replacing and verifying them.

Before deployment, confirm:

```sh
findmnt /var/lib/gns3/library
findmnt /var/lib/gns3/projects
df -h /
df -h /var/lib/gns3/library /var/lib/gns3/projects
su -s /bin/sh gns3 -c 'touch /var/lib/gns3/library/.write-test'
su -s /bin/sh gns3 -c 'touch /var/lib/gns3/projects/.write-test'
rm /var/lib/gns3/library/.write-test /var/lib/gns3/projects/.write-test
```

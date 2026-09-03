# GNS3 Buildroot appliance

This repository builds a small x86_64 GNS3 appliance for a Proxmox Q35 virtual
machine. It uses a pinned Buildroot release plus the project-specific
configuration in `br2-external`.

The build produces three disk images:

- `disk.img` contains the operating system, GNS3 server, Docker, QEMU, and the
  supporting network services.
- `gns3-templates.img` contains appliance definitions and the Alpine, MikroTik,
  and Arista images supplied locally in `inputs`.
- `gns3-projects.img` is an empty 30 GiB sparse filesystem for user projects.

The data disks are separate from the system disk so projects, Docker layers,
and appliance images do not fill the appliance root filesystem.

## Prepare the source tree

Clone the repository including its Buildroot submodule:

```sh
git clone --recurse-submodules REPOSITORY_URL
cd gns3-buildroot
make setup
```

If the repository was cloned without submodules, `make setup` initializes the
pinned Buildroot checkout. It also verifies Buildroot 2026.05.1 and applies the
small compatibility patch required by this appliance.

The build host needs the normal Buildroot dependencies, including a C/C++
compiler, GNU Make, Git, rsync, file, tar, cpio, unzip, Python, and the ext4
filesystem utilities. Docker and xz are additionally required only when
preparing a new cEOS archive.

## Supply appliance images

Vendor and prebuilt images are deliberately not committed. Place these files
under `inputs/`:

```text
inputs/alpine-virt-3.22.1.qcow2
inputs/chr-7.19.4.img.zip
inputs/ceosimage-4.29.3M-docker.tar.xz
```

Run the checksum validation before building:

```sh
make check-inputs
```

The expected hashes and notes about the original sources are in
`inputs/SHA256SUMS` and `inputs/README.md`.

To recreate the prepared Arista image from an authorized cEOS source archive,
place `cEOS64-lab-4.29.3M.tar.xz` in `inputs/`, ensure Docker is running, and
run:

```sh
scripts/prepare-ceos
```

The script refuses to replace existing Docker tags or an existing output file.
After intentionally regenerating the archive, update its checksum everywhere
identified in `inputs/README.md`.

## Build the appliance

Configure Buildroot from the committed appliance definition and start the
build:

```sh
make configure
make build
```

`make build` also loads the default configuration automatically when no
Buildroot `.config` exists. Build products are written below
`buildroot/output/images/`:

```text
buildroot/output/images/disk.img
buildroot/output/images/bzImage
buildroot/output/images/gns3-templates.img
buildroot/output/images/gns3-projects.img
```

Use `make clean` to remove compiled output while retaining the configuration,
or `make distclean` to remove both output and configuration.

## How the appliance is assembled

`br2-external/configs/gns3_proxmox_defconfig` is the top-level Buildroot
configuration. Add or remove standard Buildroot packages there. Kernel options
belong in `br2-external/board/gns3/linux.config`, while disk partitioning and
GRUB behavior are controlled by `genimage-bios.cfg` and `grub-bios.cfg` in the
same board directory.

Packages that are not supplied by upstream Buildroot live under
`br2-external/package/`. A new package needs its own directory containing a
`Config.in`, a package `.mk` file, and normally a checksum `.hash` file. Include
the package from `br2-external/Config.in`, then enable its `BR2_PACKAGE_*`
symbol in `gns3_proxmox_defconfig`.

Files copied directly into the target system belong under
`br2-external/board/gns3/rootfs-overlay/`. This is where the init scripts,
Docker defaults, sysctl settings, and libvirt network definition are maintained.
Use `post-build.sh` only for changes that must happen after Buildroot installs
all target packages, such as removing conflicting services or pruning firmware.

The templates-disk contents are assembled by `post-image-templates.sh`.
Appliance definitions and the initial GNS3 controller configuration are under
`br2-external/board/gns3/templates/`. When adding or updating an appliance
image, change its input filename and checksum in the post-image script, add or
update its `.gns3a` definition and controller entry, then document the input in
`inputs/README.md` and `inputs/SHA256SUMS`.

`post-image-projects.sh` creates the empty projects filesystem. The filesystem
labels, image sizes, and UUIDs for both data disks are defined in the two
post-image scripts. Runtime mounting behavior is implemented by the
`S55gns3-storage` init script in the root filesystem overlay.

The appliance uses libvirt only for its `virbr0` NAT network; GNS3 starts QEMU
nodes directly. Network startup is implemented by `S58libvirt-network`, and
the persistent libvirt definition is stored in the overlay under
`etc/libvirt/qemu/networks/default.xml`.

More detailed design, storage, deployment, and runtime verification notes are
available in `br2-external/README.md`.

## Validate changes

Run the repository checks before committing:

```sh
make check
```

This validates the Buildroot revision and expected patch, shell syntax, custom
package metadata, the checksum manifest, and any input files present locally.
If ShellCheck is installed, it is run as part of the checks.

The default image currently has a development root password configured in the
Buildroot defconfig. Do not expose an appliance to untrusted networks without
replacing that credential or configuring a safer login method.

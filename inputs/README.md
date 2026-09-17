# External build inputs

This directory holds appliance images that populate the GNS3 templates disk
but are not stored in Git. Supply or prepare them as described below, then run
`make check-inputs` before building.

| File | Purpose | Source or preparation |
| --- | --- | --- |
| `alpine-virt-3.22.1.qcow2` | Alpine QEMU template | Supply this exact prebuilt QCOW2; the appliance build does not generate it |
| `chr-7.19.4.img.zip` | MikroTik CHR QEMU template | Governed by the MikroTik RouterOS license |
| `cEOS64-lab-4.29.3M.tar.xz` | Source for `scripts/prepare-ceos` | Obtain through an authorized Arista account |
| `ceosimage-4.29.3M-docker.tar.xz` | Prepared cEOS image embedded in the templates disk | Generated locally; Arista terms still apply |
| `linux-7.1.4.tar.xz` | Optional local copy of the kernel source | Buildroot normally downloads this itself |

The complete image build directly requires the Alpine, CHR, and prepared cEOS
files. The original cEOS archive is only required when regenerating the
prepared archive. Run `scripts/prepare-ceos` from the repository root with
Docker running to generate the prepared archive before `make build`. The build
does not generate any file in this directory. Do not add any payload in this
directory to Git.

Alpine publishes a 3.22.1 virtual installation ISO, but this repository has no
procedure to turn that ISO into the QCOW2 expected here. Its checksum must
match `SHA256SUMS`; renaming the ISO will not work.

## Update the prepared cEOS checksum

Docker records image creation metadata, so a newly prepared archive may have a
different checksum. From the repository root, calculate its SHA-256:

```sh
sha256sum inputs/ceosimage-4.29.3M-docker.tar.xz
```

After confirming that this archive came from the intended cEOS source, copy
the 64-character hash into all three places below:

1. The `ceosimage-4.29.3M-docker.tar.xz` line in `inputs/SHA256SUMS`.
2. `CEOS_IMAGE_SHA256` in `br2-external/board/gns3/post-image-templates.sh`.
3. `ARCHIVE_SHA256` in `br2-external/board/gns3/rootfs-overlay/etc/init.d/S68ceos-image`.

Then run `make check-inputs`. Do not replace the separate hash for
`cEOS64-lab-4.29.3M.tar.xz`: that verifies the original Arista source archive,
and `scripts/prepare-ceos` checks it before preparing the Docker archive.

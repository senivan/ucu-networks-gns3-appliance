# External build inputs

This directory holds appliance images that are required to populate the GNS3
templates disk but are not stored in Git. Obtain them from their respective
vendors and verify them with `make check-inputs` before building.

| File | Purpose | Redistribution note |
| --- | --- | --- |
| `alpine-virt-3.22.1.qcow2` | Alpine QEMU template | Obtain from the official Alpine Linux downloads |
| `chr-7.19.4.img.zip` | MikroTik CHR QEMU template | Governed by the MikroTik RouterOS license |
| `cEOS64-lab-4.29.3M.tar.xz` | Source for `scripts/prepare-ceos` | Obtain through an authorized Arista account |
| `ceosimage-4.29.3M-docker.tar.xz` | Prepared cEOS image embedded in the templates disk | Generated locally; Arista terms still apply |
| `linux-7.1.4.tar.xz` | Optional local copy of the kernel source | Buildroot normally downloads this itself |

The complete image build directly requires the Alpine, CHR, and prepared cEOS
files. The original cEOS archive is only required when regenerating the
prepared archive. Do not add any payload in this directory to Git.

The checksum of a newly prepared cEOS archive can differ because Docker records
image creation metadata. After deliberately regenerating it, review and update
the cEOS checksum in `SHA256SUMS`, `post-image-templates.sh`, and
`S68ceos-image` together.

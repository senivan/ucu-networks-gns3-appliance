#!/bin/sh

set -eu

BOARD_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INPUT_DIR="$BOARD_DIR/../../../inputs"
CHR_SOURCE_ARCHIVE="$INPUT_DIR/chr-7.19.4.img.zip"
CHR_SOURCE_ARCHIVE_SHA256="e77f0d73a9c7841918debf4e9e1372f457274d58901b11463551056d9beaccf1"
CHR_IMAGE_SHA256="bb2435e35376d891590d5219e3d3ea9e3feac05a5fe415181388327dd8aeb2f9"
ALPINE_SOURCE_IMAGE="$INPUT_DIR/alpine-virt-3.22.1.qcow2"
ALPINE_IMAGE_SHA256="a049b4da77a2c723cc4fcb57e985e50cc6a5281a4ba012a65a2d0f0c69569e45"
CEOS_SOURCE_IMAGE="$INPUT_DIR/ceosimage-4.29.3M-docker.tar.xz"
CEOS_IMAGE_SHA256="acf633e4bade9d22a6f1a426666401009cb618a255752f2c0389fd90a6f54c02"
OUTPUT_IMAGE="$BINARIES_DIR/gns3-templates.img"
OUTPUT_SIZE="6G"
FILESYSTEM_UUID="bd4fc56d-e748-4cd2-9492-d037dda6f1d0"

if [ ! -f "$CHR_SOURCE_ARCHIVE" ]; then
	echo "Missing MikroTik CHR source archive: $CHR_SOURCE_ARCHIVE" >&2
	exit 1
fi

if [ ! -f "$ALPINE_SOURCE_IMAGE" ]; then
	echo "Missing Alpine source image: $ALPINE_SOURCE_IMAGE" >&2
	exit 1
fi

if [ ! -f "$CEOS_SOURCE_IMAGE" ]; then
	echo "Missing prepared cEOS Docker image: $CEOS_SOURCE_IMAGE" >&2
	exit 1
fi

printf '%s  %s\n' "$CHR_SOURCE_ARCHIVE_SHA256" "$CHR_SOURCE_ARCHIVE" |
	sha256sum -c -
printf '%s  %s\n' "$ALPINE_IMAGE_SHA256" "$ALPINE_SOURCE_IMAGE" |
	sha256sum -c -
printf '%s  %s\n' "$CEOS_IMAGE_SHA256" "$CEOS_SOURCE_IMAGE" |
	sha256sum -c -

archive_member=$(unzip -Z1 "$CHR_SOURCE_ARCHIVE")
if [ "$archive_member" != "chr-7.19.4.img" ]; then
	echo "Unexpected files in $CHR_SOURCE_ARCHIVE" >&2
	exit 1
fi

work_dir=$(mktemp -d "${BUILD_DIR:-/tmp}/gns3-templates.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

install -d \
	"$work_dir/root/images/QEMU" \
	"$work_dir/root/appliances" \
	"$work_dir/root/docker" \
	"$work_dir/root/docker-images" \
	"$work_dir/root/symbols" \
	"$work_dir/root/configs" \
	"$work_dir/root/resources"

unzip -p "$CHR_SOURCE_ARCHIVE" chr-7.19.4.img \
	> "$work_dir/root/images/QEMU/chr-7.19.4.img"
printf '%s  %s\n' \
	"$CHR_IMAGE_SHA256" \
	"$work_dir/root/images/QEMU/chr-7.19.4.img" |
	sha256sum -c -
install -m 0644 "$ALPINE_SOURCE_IMAGE" \
	"$work_dir/root/images/QEMU/alpine-virt-3.22.1.qcow2"
install -m 0644 "$CEOS_SOURCE_IMAGE" \
	"$work_dir/root/docker-images/ceosimage-4.29.3M-docker.tar.xz"

install -m 0644 "$BOARD_DIR/templates/mikrotik-chr-7.19.4.gns3a" \
	"$work_dir/root/appliances/mikrotik-chr-7.19.4.gns3a"
install -m 0644 "$BOARD_DIR/templates/alpine-virt-3.22.1.gns3a" \
	"$work_dir/root/appliances/alpine-virt-3.22.1.gns3a"
install -m 0644 "$BOARD_DIR/templates/arista-ceos-4.29.3M.gns3a" \
	"$work_dir/root/appliances/arista-ceos-4.29.3M.gns3a"
install -m 0644 "$BOARD_DIR/templates/gns3_controller.conf" \
	"$work_dir/root/configs/gns3_controller.conf"

if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
	find "$work_dir/root" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
fi

rm -f "$OUTPUT_IMAGE"
truncate -s "$OUTPUT_SIZE" "$OUTPUT_IMAGE"
E2FSPROGS_FAKE_TIME="${SOURCE_DATE_EPOCH:-0}" \
	"$HOST_DIR/sbin/mkfs.ext4" \
	-F \
	-d "$work_dir/root" \
	-L GNS3_TEMPLATES \
	-U "$FILESYSTEM_UUID" \
	-E "hash_seed=$FILESYSTEM_UUID" \
	-m 0 \
	"$OUTPUT_IMAGE"

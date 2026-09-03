#!/bin/sh

set -eu

OUTPUT_IMAGE="$BINARIES_DIR/gns3-projects.img"
OUTPUT_SIZE="30G"
FILESYSTEM_UUID="8d47fc5e-1c2f-4c42-94cb-21b5d6489baa"

rm -f "$OUTPUT_IMAGE"
truncate -s "$OUTPUT_SIZE" "$OUTPUT_IMAGE"
E2FSPROGS_FAKE_TIME="${SOURCE_DATE_EPOCH:-0}" \
	"$HOST_DIR/sbin/mkfs.ext4" \
	-F \
	-L GNS3_PROJECTS \
	-U "$FILESYSTEM_UUID" \
	-E "hash_seed=$FILESYSTEM_UUID" \
	-m 0 \
	"$OUTPUT_IMAGE"

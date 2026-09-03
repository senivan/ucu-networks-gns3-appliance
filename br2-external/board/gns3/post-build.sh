#!/bin/sh

set -e

BOARD_DIR=$(dirname "$0")

cp -f "$BOARD_DIR/grub-bios.cfg" "$TARGET_DIR/boot/grub/grub.cfg"
cp -f "$TARGET_DIR/lib/grub/i386-pc/boot.img" "$BINARIES_DIR"

# libvirt's network daemon reads persistent network definitions from this
# directory. Autostart the project-owned default network without enabling
# libvirt's QEMU driver; GNS3 launches QEMU itself.
mkdir -p "$TARGET_DIR/etc/libvirt/qemu/networks/autostart"
ln -snf ../default.xml \
	"$TARGET_DIR/etc/libvirt/qemu/networks/autostart/default.xml"

# libvirt starts a private dnsmasq instance for each virtual network. Starting
# Buildroot's system-wide dnsmasq first can prevent that instance from binding
# DNS/DHCP sockets. The executable remains installed for libvirt to use.
rm -f \
	"$TARGET_DIR/etc/init.d/S80dnsmasq" \
	"$TARGET_DIR/etc/init.d/S91virtlogd" \
	"$TARGET_DIR/etc/init.d/S92libvirtd"

# libvirt 7.10 records the firewall tool locations discovered during its Meson
# configure step as absolute /sbin paths. Buildroot installs iptables-nft's
# multi-call links in /usr/sbin, and this image deliberately does not use a
# merged /usr. Provide the exact paths libvirt validates and executes.
for firewall_tool in iptables ip6tables ebtables
do
	ln -snf "../usr/sbin/$firewall_tool" \
		"$TARGET_DIR/sbin/$firewall_tool"
done

# BR2_PACKAGE_QEMU_BLOBS installs firmware for every QEMU architecture even
# when only the i386 and x86_64 system targets are selected. Keep all x86
# BIOS, UEFI, VGA, NIC and boot ROMs, and remove only known non-x86 firmware.
for firmware in \
	'QEMU,cgthree.bin' \
	'QEMU,tcx.bin' \
	ast27x0_bootrom.bin \
	edk2-aarch64-code.fd \
	edk2-arm-code.fd \
	edk2-arm-vars.fd \
	edk2-loongarch64-code.fd \
	edk2-loongarch64-vars.fd \
	edk2-riscv-code.fd \
	edk2-riscv-vars.fd \
	hppa-firmware.img \
	hppa-firmware64.img \
	npcm7xx_bootrom.bin \
	npcm8xx_bootrom.bin \
	openbios-ppc \
	openbios-sparc32 \
	openbios-sparc64 \
	opensbi-riscv32-generic-fw_dynamic.bin \
	opensbi-riscv64-generic-fw_dynamic.bin \
	palcode-clipper \
	pnv-pnor.bin \
	qemu_vga.ndrv \
	s390-ccw.img \
	skiboot.lid \
	slof.bin \
	u-boot-sam460.bin \
	u-boot.e500 \
	vof-nvram.bin \
	vof.bin
do
	rm -f "$TARGET_DIR/usr/share/qemu/$firmware"
done

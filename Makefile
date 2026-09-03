BUILDROOT_DIR := $(CURDIR)/buildroot
BR2_EXTERNAL := $(CURDIR)/br2-external
DEFCONFIG := gns3_proxmox_defconfig
SETUP := $(CURDIR)/scripts/setup-buildroot

.DEFAULT_GOAL := help

.PHONY: help setup configure build check clean distclean

help:
	@printf '%s\n' \
		'make setup      Initialize and patch the pinned Buildroot tree' \
		'make configure  Load the GNS3 Proxmox default configuration' \
		'make build      Build the appliance and data-disk images' \
		'make check      Verify the Buildroot revision and patch state' \
		'make clean      Remove Buildroot build products' \
		'make distclean  Remove all Buildroot configuration and products'

setup:
	@$(SETUP)

configure: setup
	+$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL) $(DEFCONFIG)

build: setup
	@test -f $(BUILDROOT_DIR)/.config || \
		$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL) $(DEFCONFIG)
	+$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL)

check:
	@$(SETUP) --check

clean:
	+$(MAKE) -C $(BUILDROOT_DIR) clean

distclean:
	+$(MAKE) -C $(BUILDROOT_DIR) distclean


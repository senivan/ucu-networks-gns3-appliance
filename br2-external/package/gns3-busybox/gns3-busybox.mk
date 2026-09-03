################################################################################
#
# gns3-busybox
#
################################################################################

GNS3_BUSYBOX_VERSION = 1.38.0
GNS3_BUSYBOX_SITE = https://www.busybox.net/downloads
GNS3_BUSYBOX_SOURCE = busybox-$(GNS3_BUSYBOX_VERSION).tar.bz2
GNS3_BUSYBOX_LICENSE = GPL-2.0, bzip2-1.0.4
GNS3_BUSYBOX_LICENSE_FILES = LICENSE archival/libarchive/bz/LICENSE
GNS3_BUSYBOX_INSTALL_STAGING = YES

define GNS3_BUSYBOX_CONFIGURE_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		ARCH=x86_64 CROSS_COMPILE="$(TARGET_CROSS)" defconfig
	$(SED) 's/^# CONFIG_STATIC is not set$$/CONFIG_STATIC=y/' $(@D)/.config
	$(SED) 's/^CONFIG_TC=y$$/# CONFIG_TC is not set/' $(@D)/.config
	$(SED) 's/^CONFIG_FEATURE_TC_INGRESS=y$$/# CONFIG_FEATURE_TC_INGRESS is not set/' $(@D)/.config
	grep -qx 'CONFIG_STATIC=y' $(@D)/.config
	grep -qx '# CONFIG_TC is not set' $(@D)/.config
endef

define GNS3_BUSYBOX_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		ARCH=x86_64 CROSS_COMPILE="$(TARGET_CROSS)" \
		CFLAGS="$(TARGET_CFLAGS)"
endef

define GNS3_BUSYBOX_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 $(@D)/busybox \
		$(STAGING_DIR)/usr/libexec/gns3/busybox-static
endef

$(eval $(generic-package))

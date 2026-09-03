################################################################################
#
# ubridge
#
################################################################################

UBRIDGE_VERSION = 1.1.1
UBRIDGE_SITE = $(call github,GNS3,ubridge,v$(UBRIDGE_VERSION))
UBRIDGE_LICENSE = GPL-3.0+
UBRIDGE_LICENSE_FILES = LICENSE
UBRIDGE_DEPENDENCIES = libpcap

define UBRIDGE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -DLINUX_RAW" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define UBRIDGE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/ubridge \
		$(TARGET_DIR)/usr/bin/ubridge
endef

define UBRIDGE_PERMISSIONS
	/usr/bin/ubridge f 755 root root - - - - -
	|xattr cap_net_admin,cap_net_raw+ep
endef

$(eval $(generic-package))

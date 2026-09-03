################################################################################
#
# vpcs
#
################################################################################

VPCS_VERSION = 0.8.3
VPCS_SITE = $(call github,GNS3,vpcs,v$(VPCS_VERSION))
VPCS_LICENSE = BSD-2-Clause
VPCS_LICENSE_FILES = COPYING

define VPCS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/src -f Makefile.linux \
		CC="$(TARGET_CC) $(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS) -lpthread -lutil"
endef

define VPCS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/src/vpcs \
		$(TARGET_DIR)/usr/bin/vpcs
endef

$(eval $(generic-package))

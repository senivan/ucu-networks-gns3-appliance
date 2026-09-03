################################################################################
#
# gns3-server
#
################################################################################

GNS3_SERVER_VERSION = 2.2.60
GNS3_SERVER_SITE = $(call github,GNS3,gns3-server,v$(GNS3_SERVER_VERSION))
GNS3_SERVER_LICENSE = GPL-3.0+
GNS3_SERVER_LICENSE_FILES = LICENSE
GNS3_SERVER_SETUP_TYPE = setuptools
GNS3_SERVER_DEPENDENCIES = \
	gns3-busybox \
	python-aiofiles \
	python-aiohttp \
	python-aiohttp-cors \
	python-async-timeout \
	python-distro \
	python-gns3-platformdirs \
	python-gns3-sentry-sdk \
	python-jinja2 \
	python-jsonschema \
	python-psutil \
	python-py-cpuinfo \
	python-six \
	python-truststore \
	ubridge \
	vpcs

define GNS3_SERVER_INSTALL_STATIC_BUSYBOX
	$(INSTALL) -D -m 0755 \
		$(STAGING_DIR)/usr/libexec/gns3/busybox-static \
		$(@D)/gns3server/compute/docker/resources/bin/busybox
endef
GNS3_SERVER_PRE_BUILD_HOOKS += GNS3_SERVER_INSTALL_STATIC_BUSYBOX

define GNS3_SERVER_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(GNS3_SERVER_PKGDIR)/S70gns3 \
		$(TARGET_DIR)/etc/init.d/S70gns3
endef

define GNS3_SERVER_INSTALL_CONFIG
	$(INSTALL) -D -m 0644 $(GNS3_SERVER_PKGDIR)/gns3_server.conf \
		$(TARGET_DIR)/etc/gns3/gns3_server.conf
	ln -sf /var/lib/gns3/library/configs/gns3_controller.conf \
		$(TARGET_DIR)/etc/gns3/gns3_controller.conf
endef
GNS3_SERVER_POST_INSTALL_TARGET_HOOKS += GNS3_SERVER_INSTALL_CONFIG

define GNS3_SERVER_USERS
	gns3 -1 gns3 -1 * /var/lib/gns3 /sbin/nologin kvm,docker GNS3 service user
endef

define GNS3_SERVER_PERMISSIONS
	/var/lib/gns3 d 755 gns3 gns3 - - - - -
	/var/lib/gns3/library d 755 gns3 gns3 - - - - -
	/var/lib/gns3/library/images d 755 gns3 gns3 - - - - -
	/var/lib/gns3/library/appliances d 755 gns3 gns3 - - - - -
	/var/lib/gns3/library/symbols d 755 gns3 gns3 - - - - -
	/var/lib/gns3/library/configs d 755 gns3 gns3 - - - - -
	/var/lib/gns3/library/resources d 755 gns3 gns3 - - - - -
	/var/lib/gns3/projects d 755 gns3 gns3 - - - - -
	/var/lib/gns3/captures d 755 gns3 gns3 - - - - -
	/var/log/gns3 d 755 gns3 gns3 - - - - -
	/run/gns3 d 755 gns3 gns3 - - - - -
endef

$(eval $(python-package))

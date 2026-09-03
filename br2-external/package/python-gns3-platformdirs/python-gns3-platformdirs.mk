################################################################################
#
# python-gns3-platformdirs
#
################################################################################

PYTHON_GNS3_PLATFORMDIRS_VERSION = 2.6.2
PYTHON_GNS3_PLATFORMDIRS_SOURCE = platformdirs-$(PYTHON_GNS3_PLATFORMDIRS_VERSION).tar.gz
PYTHON_GNS3_PLATFORMDIRS_SITE = https://files.pythonhosted.org/packages/cf/4d/198b7e6c6c2b152f4f9f4cdf975d3590e33e63f1920f2d89af7f0390e6db
PYTHON_GNS3_PLATFORMDIRS_SETUP_TYPE = hatch
PYTHON_GNS3_PLATFORMDIRS_LICENSE = MIT
PYTHON_GNS3_PLATFORMDIRS_LICENSE_FILES = LICENSE
PYTHON_GNS3_PLATFORMDIRS_DEPENDENCIES = host-python-hatch-vcs

$(eval $(python-package))

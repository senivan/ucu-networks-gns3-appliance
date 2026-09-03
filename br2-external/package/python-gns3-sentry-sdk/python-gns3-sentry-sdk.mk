################################################################################
#
# python-gns3-sentry-sdk
#
################################################################################

PYTHON_GNS3_SENTRY_SDK_VERSION = 2.59.0
PYTHON_GNS3_SENTRY_SDK_SOURCE = sentry_sdk-$(PYTHON_GNS3_SENTRY_SDK_VERSION).tar.gz
PYTHON_GNS3_SENTRY_SDK_SITE = https://files.pythonhosted.org/packages/65/e0/9bf5e5fc7442b10880f3ec0eff0ef4208b84a099606f343ec4f5445227fb
PYTHON_GNS3_SENTRY_SDK_SETUP_TYPE = setuptools
PYTHON_GNS3_SENTRY_SDK_LICENSE = MIT
PYTHON_GNS3_SENTRY_SDK_LICENSE_FILES = LICENSE

$(eval $(python-package))

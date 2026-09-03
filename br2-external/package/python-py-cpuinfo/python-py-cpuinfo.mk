################################################################################
#
# python-py-cpuinfo
#
################################################################################

PYTHON_PY_CPUINFO_VERSION = 9.0.0
PYTHON_PY_CPUINFO_SOURCE = py-cpuinfo-$(PYTHON_PY_CPUINFO_VERSION).tar.gz
PYTHON_PY_CPUINFO_SITE = https://files.pythonhosted.org/packages/37/a8/d832f7293ebb21690860d2e01d8115e5ff6f2ae8bbdc953f0eb0fa4bd2c7
PYTHON_PY_CPUINFO_SETUP_TYPE = setuptools
PYTHON_PY_CPUINFO_LICENSE = MIT
PYTHON_PY_CPUINFO_LICENSE_FILES = LICENSE

$(eval $(python-package))

#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# This file was automatically generated using the following command:
#   $WS_TOOLS/python-integrate-project ruamel.yaml
#

BUILD_STYLE = setup.py

include ../../../make-rules/shared-macros.mk

COMPONENT_NAME =		ruamel.yaml
HUMAN_VERSION =			0.18.10
COMPONENT_SUMMARY =		ruamel.yaml is a YAML parser/emitter that supports roundtrip preservation of comments, seq/map flow style, and map key order
COMPONENT_ARCHIVE_URL =		\
	https://sourceforge.net/projects/ruamel-dl-tagged-releases/files/$(COMPONENT_ARCHIVE)/download
COMPONENT_ARCHIVE_HASH =	\
	sha256:936fd45ef68ec6d0ee6aaac8d9f786f70e001d056089317cf62b2c8c6bba7440
COMPONENT_LICENSE =		MIT
COMPONENT_LICENSE_FILE =	LICENSE

COMPONENT_ARCHIVE =		$(COMPONENT_SRC).tar.xz

include $(WS_MAKE_RULES)/common.mk

# Random directory name
COMPONENT_TEST_TRANSFORMS += "-e 's|/tmp/.*/garbage[^/]*|\$$(TMPDIR)|'"

# Auto-generated dependencies
PYTHON_REQUIRED_PACKAGES += library/python/ruamel-yaml-clib
PYTHON_REQUIRED_PACKAGES += runtime/python
TEST_REQUIRED_PACKAGES.python += library/python/pytest
TEST_REQUIRED_PACKAGES.python += library/python/setuptools

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
#   $WS_TOOLS/python-integrate-project aiohappyeyeballs
#

BUILD_STYLE = pyproject

include ../../../make-rules/shared-macros.mk

COMPONENT_NAME =		aiohappyeyeballs
HUMAN_VERSION =			2.6.1
COMPONENT_SUMMARY =		Happy Eyeballs for asyncio
COMPONENT_ARCHIVE_HASH =	\
	sha256:c3f9d0113123803ccadfdf3f0faa505bc78e6a72d1cc4806cbd719826e943558
COMPONENT_LICENSE =		PSF-2.0
COMPONENT_LICENSE_FILE =	LICENSE

TEST_STYLE = pytest

include $(WS_MAKE_RULES)/common.mk

# This project uses poetry to manage test dependencies.
TEST_REQUIREMENTS_POETRY += dev

# Auto-generated dependencies
PYTHON_REQUIRED_PACKAGES += library/python/poetry-core
PYTHON_REQUIRED_PACKAGES += runtime/python
TEST_REQUIRED_PACKAGES.python += library/python/pytest
TEST_REQUIRED_PACKAGES.python += library/python/pytest-asyncio
TEST_REQUIRED_PACKAGES.python += library/python/pytest-cov

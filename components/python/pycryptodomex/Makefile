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
#   $WS_TOOLS/python-integrate-project pycryptodomex
#

BUILD_STYLE = pyproject

include ../../../make-rules/shared-macros.mk

COMPONENT_NAME =		pycryptodomex
HUMAN_VERSION =			3.22.0
COMPONENT_SUMMARY =		Cryptographic library for Python
COMPONENT_PROJECT_URL =		https://www.pycryptodome.org
COMPONENT_ARCHIVE_HASH =	\
	sha256:a1da61bacc22f93a91cbe690e3eb2022a03ab4123690ab16c46abb693a9df63d
COMPONENT_LICENSE =		BSD-2-Clause
COMPONENT_LICENSE_FILE =	LICENSE.rst

# https://github.com/Legrandin/pycryptodome/issues/731
TEST_STYLE = setup.py

include $(WS_MAKE_RULES)/common.mk

# get verbose test output
COMPONENT_TEST_TARGETS += -vv

# This project does not support tox so we need to provide test requirements
# manually.
TEST_REQUIREMENTS += requirements-test.txt

# Auto-generated dependencies
PYTHON_REQUIRED_PACKAGES += library/python/setuptools
PYTHON_REQUIRED_PACKAGES += runtime/python
REQUIRED_PACKAGES += system/library
TEST_REQUIRED_PACKAGES.python += library/python/pycryptodome-test-vectors

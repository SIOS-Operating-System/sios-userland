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
#   $WS_TOOLS/python-integrate-project zope.testrunner
#

BUILD_STYLE = pyproject

include ../../../make-rules/shared-macros.mk

COMPONENT_NAME =		zope.testrunner
HUMAN_VERSION =			7.2
COMPONENT_SUMMARY =		Zope testrunner script.
COMPONENT_PROJECT_URL =		https://github.com/zopefoundation/zope.testrunner
COMPONENT_ARCHIVE_HASH =	\
	sha256:d4fae0ba3b0e287a60591a9e350ddf7cb3150b73951eecfa835f80d0abe61280
COMPONENT_LICENSE =		ZPL-2.1
COMPONENT_LICENSE_FILE =	LICENSE.md

COMPONENT_SRC =			zope_testrunner-$(HUMAN_VERSION)

#
# Following dependency loops were detected (where 'A --> B' means 'A needs B to
# run tests', and 'A ==> B' means 'A needs B for build and/or run'):
#
# zope.testrunner --> zope.testing --> zope.testrunner
#
# To break loops we need to allow this project to integrate without testing in
# a case the required projects are not available yet (bootstrap).
#
PYTHON_TEST_BOOTSTRAP = yes

include $(WS_MAKE_RULES)/common.mk

# Force no colors and more verbose output via tox posargs
TOX_POSARGS += -vv

# Random pid
COMPONENT_TEST_TRANSFORMS += "-e 's/\(subprocess \)[0-9]\{1,\}\( is still running\)/\1\$$(PID)\2/'"

# Auto-generated dependencies
PYTHON_REQUIRED_PACKAGES += library/python/setuptools
PYTHON_REQUIRED_PACKAGES += library/python/zope-exceptions
PYTHON_REQUIRED_PACKAGES += library/python/zope-interface
PYTHON_REQUIRED_PACKAGES += runtime/python
TEST_REQUIRED_PACKAGES.python += library/python/setuptools
TEST_REQUIRED_PACKAGES.python += library/python/zope-testing

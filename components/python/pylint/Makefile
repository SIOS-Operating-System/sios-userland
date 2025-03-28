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
#   $WS_TOOLS/python-integrate-project pylint
#

BUILD_STYLE = pyproject

include ../../../make-rules/shared-macros.mk

COMPONENT_NAME =		pylint
HUMAN_VERSION =			3.3.5
COMPONENT_SUMMARY =		python code static checker
COMPONENT_ARCHIVE_HASH =	\
	sha256:38d0f784644ed493d91f76b5333a0e370a1c1bc97c22068a77523b4bf1e82c31
COMPONENT_LICENSE =		GPL-2.0-only
COMPONENT_LICENSE_FILE =	LICENSE

include $(WS_MAKE_RULES)/common.mk

# Some tests are failing when run under pytest 8 so we simply remove them.
# https://github.com/pylint-dev/pylint/issues/9477
# https://github.com/pylint-dev/pylint/pull/9576
COMPONENT_PREP_ACTION += \
	for t in \
		i/inconsistent/inconsistent_quotes_fstring \
		i/inconsistent/inconsistent_returns \
		i/invalid/invalid_all/invalid_all_format_valid_5 \
		i/invalid/invalid_all/invalid_all_format_valid_6 \
		n/no/no_name_in_module \
		r/regression/regression_4680 \
		u/unreachable \
		u/undefined/undefined_variable_typing \
		u/unused/unused_import_assigned_to \
		u/use/use_yield_from \
		u/used/used_before_assignment \
		u/used/used_before_assignment_else_return \
	; do \
		$(RM) -r $(SOURCE_DIR)/tests/functional/$${t}.* ; \
	done ;

# Test results order varies between runs
PYTEST_SORT_TESTS = yes

# Random directory name
COMPONENT_TEST_TRANSFORMS += "-e 's|/tmp/.*/garbage[^/]*|\$$(TMPDIR)|'"

# Auto-generated dependencies
PYTHON_REQUIRED_PACKAGES += library/python/astroid
PYTHON_REQUIRED_PACKAGES += library/python/dill
PYTHON_REQUIRED_PACKAGES += library/python/isort
PYTHON_REQUIRED_PACKAGES += library/python/mccabe
PYTHON_REQUIRED_PACKAGES += library/python/platformdirs
PYTHON_REQUIRED_PACKAGES += library/python/setuptools
PYTHON_REQUIRED_PACKAGES += library/python/tomli
PYTHON_REQUIRED_PACKAGES += library/python/tomlkit
PYTHON_REQUIRED_PACKAGES += library/python/typing-extensions
PYTHON_REQUIRED_PACKAGES += runtime/python
TEST_REQUIRED_PACKAGES.python += library/python/astroid
TEST_REQUIRED_PACKAGES.python += library/python/coverage
TEST_REQUIRED_PACKAGES.python += library/python/gitpython
TEST_REQUIRED_PACKAGES.python += library/python/pip
TEST_REQUIRED_PACKAGES.python += library/python/py
TEST_REQUIRED_PACKAGES.python += library/python/pytest
TEST_REQUIRED_PACKAGES.python += library/python/pytest-benchmark
TEST_REQUIRED_PACKAGES.python += library/python/pytest-cov
TEST_REQUIRED_PACKAGES.python += library/python/pytest-timeout
TEST_REQUIRED_PACKAGES.python += library/python/pytest-xdist
TEST_REQUIRED_PACKAGES.python += library/python/requests
TEST_REQUIRED_PACKAGES.python += library/python/six
TEST_REQUIRED_PACKAGES.python += library/python/types-setuptools
TEST_REQUIRED_PACKAGES.python += library/python/typing-extensions

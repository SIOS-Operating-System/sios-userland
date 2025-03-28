#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright (c) 2010, 2016, Oracle and/or its affiliates. All rights reserved.
#

#
# The Python build infrastructure in setup.py.mk and pyproject.mk files uses
# several Python projects to work properly.  Since we cannot use these projects
# until they are actually built and installed we need to bootstrap.
#
# We do have several sequential bootstrap checkpoints during the process:
#
# (0)	Nothing works yet.
#
# 	Just core Python runtime is available (with no additional projects).
# 	While here almost nothing works.  We cannot do following tasks with
# 	regular Python projects:
# 		- detect their requirements,
# 		- build and publish them,
# 		- test them.
#
# (1) 	The bootstrapper is ready.
#
# 	The bootstrapper is special tool that requires just core Python with no
# 	dependency on other Python projects and it is able to build and publish
# 	itself and other Python projects.
#
# 	For projects using the 'setup.py' build style we do not need any
# 	special bootstrapper because such projects are built using their own
# 	'setup.py' script.  The only issue with the 'setup.py' build style
# 	projects is that their 'setup.py' script usually depends on some other
# 	projects (typically setuptools) to get successfully built.
#
# 	For 'pyproject'-style projects we use pyproject_installer as the
# 	bootstrapper.
#
# 	To achieve this checkpoint we just need to build pyproject_installer
# 	using pyproject_installer without detecting its requirements (they are
# 	none anyway) and without testing it (since no testing infrastructure is
# 	ready yet).
#
# (2)	The python-requires script works.
#
# 	Once the python-requires script works we can start to detect runtime
# 	dependencie of other Python projects automatically.
#
# 	To achieve this checkpoint we need to build the packaging project
# 	(directly needed by the python-requires script) and all projects
# 	required by packaging.  During this all projects' dependencies needs to
# 	be manually evaluated to make sure they are correct.
#
# (3)	The build infrastructure is fully working.
#
#	Once we are here we can build any Python project, but we cannot test it
#	yet.
#
# 	For projects using the 'setup.py' build style we do not need any
# 	special build infrastructure.  See checkpoint (1) above for detialed
# 	discussion about 'setup.py' build style projects.
#
# 	For 'pyproject'-style projects we need to build both 'build' and
# 	'installer' projects and all projects they depends on.
#
# (4)	The testing infrastructure is fully working.
#
# 	Once we are here we can finally use all features of the Python build
# 	framework.  Including testing.
#
# 	To achieve this we need to build tox, tox-current-env, and pytest
# 	projects together with their dependencies.
#
# All projects needed to achieve checkpoints (1), (2), and (3) should set
# PYTHON_BOOTSTRAP to 'yes' in their Makefile to make sure the regular build
# infrastructure is not used for them and special set of build rules is applied
# instead.
#
# All projects needed to go from checkpoint (3) to checkpoint (4) should set
# PYTHON_TEST_BOOTSTRAP to 'yes' in their Makefile to let the build
# infrastructure know that testing for such projects might not work properly.
#
# The PYTHON_BOOTSTRAP set to 'yes' implies PYTHON_TEST_BOOTSTRAP set to 'yes'
# too.
#
ifeq ($(strip $(PYTHON_BOOTSTRAP)),yes)
PYTHON_TEST_BOOTSTRAP = yes
endif

#
# Lists of Python projects needed to achieve particular bootstrap checkpoint.
# Indentation shows project dependencies (e.g. packaging requires flit_core).
#
PYTHON_BOOTSTRAP_CHECKPOINT_1 +=	pyproject_installer
#
PYTHON_BOOTSTRAP_CHECKPOINT_2 +=	$(PYTHON_BOOTSTRAP_CHECKPOINT_1)
PYTHON_BOOTSTRAP_CHECKPOINT_2 +=	packaging
PYTHON_BOOTSTRAP_CHECKPOINT_2 +=		flit_core

# Particular python runtime is always required (at least to run setup.py)
PYTHON_REQUIRED_PACKAGES += runtime/python

define python-rule
$(BUILD_DIR)/%-$(1)/.built:		PYTHON_VERSION=$(1)
$(BUILD_DIR)/%-$(1)/.installed:		PYTHON_VERSION=$(1)
$(BUILD_DIR)/%-$(1)/.tested:		PYTHON_VERSION=$(1)
$(BUILD_DIR)/%-$(1)/.tested-and-compared:	PYTHON_VERSION=$(1)
endef

$(foreach pyver, $(PYTHON_VERSIONS), $(eval $(call python-rule,$(pyver))))

$(BUILD_DIR)/$(MACH32)-%/.built:	BITS=32
$(BUILD_DIR)/$(MACH64)-%/.built:	BITS=64
$(BUILD_DIR)/$(MACH32)-%/.installed:	BITS=32
$(BUILD_DIR)/$(MACH64)-%/.installed:	BITS=64
$(BUILD_DIR)/$(MACH32)-%/.tested:	BITS=32
$(BUILD_DIR)/$(MACH64)-%/.tested:	BITS=64
$(BUILD_DIR)/$(MACH32)-%/.tested-and-compared:	BITS=32
$(BUILD_DIR)/$(MACH64)-%/.tested-and-compared:	BITS=64

PYTHON_32_VERSIONS = $(filter-out $(PYTHON_64_ONLY_VERSIONS), $(PYTHON_VERSIONS))

BUILD_32 = $(PYTHON_32_VERSIONS:%=$(BUILD_DIR)/$(MACH32)-%/.built)
BUILD_64 = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH64)-%/.built)
BUILD_NO_ARCH = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH)-%/.built)

ifeq ($(filter-out $(PYTHON_64_ONLY_VERSIONS), $(PYTHON_VERSION)),)
BUILD_32_and_64 = $(BUILD_64)
endif

INSTALL_32 = $(PYTHON_32_VERSIONS:%=$(BUILD_DIR)/$(MACH32)-%/.installed)
INSTALL_64 = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH64)-%/.installed)
INSTALL_NO_ARCH = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH)-%/.installed)

PYTHON_ENV =	CC="$(CC)"
PYTHON_ENV +=	CFLAGS="$(CFLAGS)"
PYTHON_ENV +=	CXX="$(CXX)"
PYTHON_ENV +=	CXXFLAGS="$(CXXFLAGS)"
PYTHON_ENV +=	LDFLAGS="$(LDFLAGS)"
PYTHON_ENV +=	PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)"

COMPONENT_BUILD_ENV += $(PYTHON_ENV)
COMPONENT_INSTALL_ENV += $(PYTHON_ENV)
COMPONENT_TEST_ENV += $(PYTHON_ENV)

# Set CARGO_HOME to make sure projects built using rust (for example via
# setuptools-rust) do not pollute user's home directory with cargo bits.
COMPONENT_BUILD_ENV += CARGO_HOME=$(@D)/.cargo
# Similarly, force our preferred target linker for cargo.
COMPONENT_BUILD_ENV += CARGO_TARGET_$(shell echo $(RUST_TRIPLET) | $(TR) '[a-z]-' '[A-Z]_')_LINKER=$(CARGO_TARGET_LINKER)

# Make sure the default Python version is installed last and so is the
# canonical version.  This is needed for components that keep PYTHON_VERSIONS
# set to more than single value, but deliver unversioned binaries in usr/bin or
# other overlapping files.
define python-order-rule
$(BUILD_DIR)/%-$(PYTHON_VERSION)/.installed:	$(BUILD_DIR)/%-$(1)/.installed
endef
$(foreach pyver,$(filter-out $(PYTHON_VERSION),$(PYTHON_VERSIONS)),$(eval $(call python-order-rule,$(pyver))))

# We need to copy the source dir to avoid its modification by install target
# where egg-info is re-generated
CLONEY_ARGS = CLONEY_MODE="copy"

COMPONENT_CONFIGURE_ACTION = true

COMPONENT_BUILD_CMD = $(PYTHON) setup.py --no-user-cfg build $(COMPONENT_BUILD_SETUP_PY_ARGS)


COMPONENT_INSTALL_CMD = $(PYTHON) setup.py --no-user-cfg install

COMPONENT_INSTALL_ARGS +=	--root $(PROTO_DIR) 
COMPONENT_INSTALL_ARGS +=	--install-lib=$(PYTHON_LIB)
COMPONENT_INSTALL_ARGS +=	--install-data=$(PYTHON_DATA)
COMPONENT_INSTALL_ARGS +=	--skip-build
COMPONENT_INSTALL_ARGS +=	--force

# this is needed to override the default set in shared-macros.mk
COMPONENT_INSTALL_TARGETS =

ifeq ($(strip $(SINGLE_PYTHON_VERSION)),no)
# Rename binaries in /usr/bin to contain version number
COMPONENT_POST_INSTALL_ACTION += \
	for f in $(PROTOUSRBINDIR)/* ; do \
		[ -f $$f ] || continue ; \
		for v in $(PYTHON_VERSIONS) ; do \
			[ "$$f" == "$${f%%$$v}" ] || continue 2 ; \
		done ; \
		$(MV) $$f $$f-$(PYTHON_VERSION) ; \
	done ;
endif

# Remove any previous dependency files
COMPONENT_POST_INSTALL_ACTION +=	$(RM) $(@D)/.depend-runtime $(@D)/.depend-test ;

# Define Python version specific filenames for tests.
ifeq ($(strip $(USE_COMMON_TEST_MASTER)),no)
COMPONENT_TEST_MASTER =	$(COMPONENT_TEST_RESULTS_DIR)/results-$(PYTHON_VERSION).master
endif
COMPONENT_TEST_BUILD_DIR = $(BUILD_DIR)/test-$(PYTHON_VERSION)
COMPONENT_TEST_OUTPUT =	$(COMPONENT_TEST_BUILD_DIR)/test-$(PYTHON_VERSION)-results
COMPONENT_TEST_DIFFS =	$(COMPONENT_TEST_BUILD_DIR)/test-$(PYTHON_VERSION)-diffs
COMPONENT_TEST_SNAPSHOT = $(COMPONENT_TEST_BUILD_DIR)/results-$(PYTHON_VERSION).snapshot
COMPONENT_TEST_TRANSFORM_CMD = $(COMPONENT_TEST_BUILD_DIR)/transform-$(PYTHON_VERSION)-results

# Generic transforms for Python test results.
# See below for test style specific transforms.
COMPONENT_TEST_TRANSFORMS += "-e 's|$(PYTHON_DIR)|\$$(PYTHON_DIR)|g'"

# Testing depends on install target because we want to test installed modules
COMPONENT_TEST_DEP +=	$(BUILD_DIR)/%/.installed
# Point Python to the proto area so it is able to find installed modules there
COMPONENT_TEST_ENV +=	PYTHONPATH=$(PROTO_DIR)/$(PYTHON_LIB)
# Make sure testing is able to find own installed executables (if any)
COMPONENT_TEST_ENV +=	PATH=$(PROTOUSRBINDIR):$(PATH)

# determine the type of tests we want to run.
ifeq ($(strip $(wildcard $(COMPONENT_TEST_RESULTS_DIR)/results-*.master)),)
TEST_32 = $(PYTHON_32_VERSIONS:%=$(BUILD_DIR)/$(MACH32)-%/.tested)
TEST_64 = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH64)-%/.tested)
TEST_NO_ARCH = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH)-%/.tested)
else
TEST_32 = $(PYTHON_32_VERSIONS:%=$(BUILD_DIR)/$(MACH32)-%/.tested-and-compared)
TEST_64 = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH64)-%/.tested-and-compared)
TEST_NO_ARCH = $(PYTHON_VERSIONS:%=$(BUILD_DIR)/$(MACH)-%/.tested-and-compared)
endif

#
# Testing in the Python world is complex.  Python projects usually do not
# support Makefile with common 'check' or 'test' target to get built bits
# tested.
#
# De facto standard way to test Python projects these days is tox which is
# designed and used primarily for release testing; to make sure the released
# python project runs on all supported Python versions, platforms, etc.  tox
# does so using virtualenv and creates isolated test environments where the
# tested package together with all its dependencies is automatically installed
# (using pip) and tested.  This is great for Python projects developers but it
# is hardly usable for operating system distributions like OpenIndiana.
#
# We do not need such release testing.  Instead we need something closer to
# integration testing: we need to test the built component in our real
# environment without automatic installation of any dependencies using pip.  In
# addition, we need to run tests only for Python versions we actually support
# and the component is built for.
#
# To achieve that we do few things.  First, to avoid isolated environments
# (virtualenv) we run tox with the tox-current-env plugin.  Second, to test
# only Python versions we are interested in we use -e option for tox to select
# single Python version only.  Since we run separate test target per Python
# version this will make sure we test all needed Python versions.
#
# The tox tool itself uses some other tools under the hood to run tests, for
# example pytest.  Some projects could even support pytest testing directly
# without support for tox.  For such projects we offer separate "pytest"-style
# testing.
#
# For projects that do not support testing using neither tox nor pytest we
# offer either unittest or (deprecated) "setup.py test" testing too.
#
# The TEST_STYLE variable is used to select (or force) particular test style
# for Python projects.  Valid values are:
#
# 	tox		- "tox"-style testing
# 	pytest		- "pytest"-style testing
# 	unittest	- "unittest"-style testing
# 	setup.py	- "setup.py test"-style testing
# 	none		- no testing is supported (or desired) at all
#

TEST_STYLE ?= tox
ifeq ($(strip $(TEST_STYLE)),tox)
# tox needs PATH environment variable - see https://github.com/tox-dev/tox/issues/2538
# We already added it to the test environment - see above
COMPONENT_TEST_ENV +=		PYTEST_ADDOPTS="$(PYTEST_ADDOPTS)"
COMPONENT_TEST_ENV +=		NOSE_VERBOSE=2
COMPONENT_TEST_CMD =		$(TOX)
COMPONENT_TEST_ARGS =		--current-env --no-provision
COMPONENT_TEST_ARGS +=		--recreate
COMPONENT_TEST_ARGS +=		$(TOX_TESTENV)
COMPONENT_TEST_TARGETS =	$(if $(strip $(TOX_POSARGS)),-- $(TOX_POSARGS))

TOX_TESTENV = -e py$(subst .,,$(PYTHON_VERSION))

# Make sure following tools are called indirectly to properly support tox-current-env
TOX_CALL_INDIRECTLY += py.test
TOX_CALL_INDIRECTLY += pytest
TOX_CALL_INDIRECTLY += coverage
TOX_CALL_INDIRECTLY += zope-testrunner
TOX_CALL_INDIRECTLY.zope-testrunner = zope.testrunner
TOX_CALL_INDIRECTLY += sphinx-build
TOX_CALL_INDIRECTLY.sphinx-build = sphinx.cmd.build
TOX_CALL_INDIRECTLY += nosetests
TOX_CALL_INDIRECTLY.nosetests = nose
$(foreach indirectly, $(TOX_CALL_INDIRECTLY), $(eval TOX_CALL_INDIRECTLY.$(indirectly) ?= $(indirectly)))
COMPONENT_PRE_TEST_ACTION += COMPONENT_TEST_DIR=$(COMPONENT_TEST_DIR) ;
COMPONENT_PRE_TEST_ACTION += \
	$(foreach indirectly, $(TOX_CALL_INDIRECTLY), \
		[ -f $$COMPONENT_TEST_DIR/tox.ini ] && \
			$(GSED) -i -e '/^commands *=/,/^$$/{ \
				s/^\(\(commands *=\)\{0,1\}[ \t]*\)'$(indirectly)'\([ \t]\{1,\}.*\)\{0,1\}$$/\1python -m '$(TOX_CALL_INDIRECTLY.$(indirectly))'\3/ \
			}' $$COMPONENT_TEST_DIR/tox.ini ; \
	)
COMPONENT_PRE_TEST_ACTION += true ;

# Normalize tox test results.
COMPONENT_TEST_TRANSFORMS += "-e 's/py$(subst .,,$(PYTHON_VERSION))/py\$$(PYV)/g'"	# normalize PYV
COMPONENT_TEST_TRANSFORMS += "-e '/^py\$$(PYV) installed:/d'"		# depends on set of installed packages
COMPONENT_TEST_TRANSFORMS += "-e '/PYTHONHASHSEED/d'"			# this is random

# Normalize zope.testrunner test results
COMPONENT_TEST_TRANSFORMS += \
	"-e 's/ in \([0-9]\{1,\} minutes \)\{0,1\}[0-9]\{1,\}\.[0-9]\{3\} seconds//'"	# timing

# Remove timing for tox 4 test results
COMPONENT_TEST_TRANSFORMS += "-e 's/^\(  py\$$(PYV): OK\) (.* seconds)$$/\1/'"
COMPONENT_TEST_TRANSFORMS += "-e 's/^\(  congratulations :)\) (.* seconds)$$/\1/'"

# Remove useless lines from the "coverage combine" output
COMPONENT_TEST_TRANSFORMS += "-e '/^Combined data file .*\.coverage/d'"
COMPONENT_TEST_TRANSFORMS += "-e '/^Skipping duplicate data .*\.coverage/d'"

# sort list of Sphinx doctest results
COMPONENT_TEST_TRANSFORMS += \
	"| ( \
		$(GSED) -u -e '/^running tests\.\.\.$$/q' ; \
		$(GSED) -u -e '/^Doctest summary/Q' \
			| $(NAWK) '/^$$/{\$$0=\"\\\\n\"}1' ORS='|' \
			| $(GNU_GREP) -v '^|$$' \
			| $(SORT) \
			| tr -d '\\\\n' | tr '|' '\\\\n' \
			| $(NAWK) '{print}END{if(NR>0)printf(\"\\\\nDoctest summary\\\\n\")}' ; \
		$(CAT) \
	) | $(COMPONENT_TEST_TRANSFORMER)"

# tox package together with the tox-current-env plugin is needed
USERLAND_TEST_REQUIRED_PACKAGES += library/python/tox
USERLAND_TEST_REQUIRED_PACKAGES += library/python/tox-current-env

# Generate raw lists of test dependencies per Python version
# Please note we set PATH below five times for tox to workaround
# https://github.com/tox-dev/tox/issues/2538
COMPONENT_POST_INSTALL_ACTION += \
	if [ -x "$(TOX)" ] ; then \
		cd $(@D)$(COMPONENT_SUBDIR:%=/%) ; \
		echo "Testing dependencies:" ; \
		PATH=$(PATH) PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
			$(TOX) -qq --no-provision --print-deps-to=- $(TOX_TESTENV) || exit 1 ; \
		echo "Testing extras:" ; \
		PATH=$(PATH) PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
			$(TOX) -qq --no-provision --print-extras-to=- $(TOX_TESTENV) || exit 1 ; \
		echo "Testing dependency groups:" ; \
		PATH=$(PATH) PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
			$(TOX) -qq --no-provision --print-dependency-groups-to=- $(TOX_TESTENV) || exit 1 ; \
		( PATH=$(PATH) PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
			$(TOX) -qq --no-provision --print-deps-to=- $(TOX_TESTENV) \
			| $(WS_TOOLS)/python-resolve-deps \
				PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
				$(PYTHON) $(WS_TOOLS)/python-requires $(COMPONENT_NAME) \
			| $(PYTHON) $(WS_TOOLS)/python-requires - ; \
		for e in $$(PATH=$(PATH) PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
			$(TOX) -qq --no-provision --print-extras-to=- $(TOX_TESTENV)) ; do \
			PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
				$(PYTHON) $(WS_TOOLS)/python-requires $(COMPONENT_NAME) $$e ; \
		done \
		) | $(GSED) -e '/^tox\(-current-env\)\?$$/d' >> $(@D)/.depend-test ; \
	fi ;
else ifeq ($(strip $(TEST_STYLE)),pytest)
COMPONENT_TEST_CMD =		$(PYTHON) -m pytest
COMPONENT_TEST_ARGS =		$(PYTEST_ADDOPTS)
COMPONENT_TEST_TARGETS =

USERLAND_TEST_REQUIRED_PACKAGES += library/python/pytest
else ifeq ($(strip $(TEST_STYLE)),unittest)
COMPONENT_TEST_CMD =		$(PYTHON) -m unittest
COMPONENT_TEST_ARGS =
COMPONENT_TEST_ARGS +=		--verbose
COMPONENT_TEST_TARGETS =
else ifeq ($(strip $(TEST_STYLE)),setup.py)
# Old and deprecated "setup.py test"-style testing
COMPONENT_TEST_CMD =		$(PYTHON) setup.py
COMPONENT_TEST_ARGS =		--no-user-cfg
COMPONENT_TEST_TARGETS =	test
else ifeq ($(strip $(TEST_STYLE)),none)
TEST_TARGET = $(NO_TESTS)
endif

# Run pytest verbose to get separate line per test in results output
PYTEST_ADDOPTS += --verbose

# Force pytest to not use colored output so the results normalization is unaffected
PYTEST_ADDOPTS += --color=no

# Create list of required pytest plugins.
define pytest-plugin
PYTEST_PLUGINS += $$(if $$(filter library/python/$(1)-$$(subst .,,$$(PYTHON_VERSION)), $$(REQUIRED_PACKAGES) $$(TEST_REQUIRED_PACKAGES) $$(COMPONENT_FMRI)-$$(subst .,,$$(PYTHON_VERSION))),$(2))
endef
$(eval $(call pytest-plugin,anyio,anyio))
$(eval $(call pytest-plugin,betamax,pytest-betamax))
$(eval $(call pytest-plugin,faker,faker))
$(eval $(call pytest-plugin,flaky,flaky))
$(eval $(call pytest-plugin,hypothesis,hypothesispytest))
$(eval $(call pytest-plugin,inline-snapshot,inline_snapshot))
$(eval $(call pytest-plugin,jaraco-test,jaraco.test.http))
$(eval $(call pytest-plugin,jaraco-vcs,jaraco.vcs.fixtures))
$(eval $(call pytest-plugin,kgb,kgb))
$(eval $(call pytest-plugin,pyfakefs,pytest_fakefs))
$(eval $(call pytest-plugin,pytest-asyncio,asyncio))
$(eval $(call pytest-plugin,pytest-benchmark,benchmark))
$(eval $(call pytest-plugin,pytest-black,black))
$(eval $(call pytest-plugin,pytest-check,check))
$(eval $(call pytest-plugin,pytest-checkdocs,checkdocs))
$(eval $(call pytest-plugin,pytest-console-scripts,console-scripts))
$(eval $(call pytest-plugin,pytest-cov,pytest_cov))
$(eval $(call pytest-plugin,pytest-custom-exit-code,custom_exit_code))
$(eval $(call pytest-plugin,pytest-datadir,pytest-datadir))
$(eval $(call pytest-plugin,pytest-enabler,enabler))
$(eval $(call pytest-plugin,pytest-env,env))
$(eval $(call pytest-plugin,pytest-expect,pytest_expect))
$(eval $(call pytest-plugin,pytest-flake8,flake8))
$(eval $(call pytest-plugin,pytest-forked,pytest_forked))
$(eval $(call pytest-plugin,pytest-freezer,freezer))
$(eval $(call pytest-plugin,pytest-helpers-namespace,helpers_namespace))
$(eval $(call pytest-plugin,pytest-home,home))
$(eval $(call pytest-plugin,pytest-httpserver,pytest_httpserver))
$(eval $(call pytest-plugin,pytest-ignore-flaky,pytest_ignore_flaky))
$(eval $(call pytest-plugin,pytest-lazy-fixtures,pytest_lazyfixture))
$(eval $(call pytest-plugin,pytest-metadata,metadata))
$(eval $(call pytest-plugin,pytest-mock,pytest_mock))
$(eval $(call pytest-plugin,pytest-mypy,mypy))
$(eval $(call pytest-plugin,pytest-mypy-plugins,pytest-mypy-plugins))
$(eval $(call pytest-plugin,pytest-perf,perf))
$(eval $(call pytest-plugin,pytest-randomly,randomly))
$(eval $(call pytest-plugin,pytest-regressions,regressions))
$(eval $(call pytest-plugin,pytest-relaxed,relaxed))
$(eval $(call pytest-plugin,pytest-reporter,reporter))
$(eval $(call pytest-plugin,pytest-rerunfailures,rerunfailures))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories-event-listener))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories-factories))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories-loader-mock))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories-log-server))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories-markers))
$(eval $(call pytest-plugin,pytest-salt-factories,salt-factories-sysinfo))
$(eval $(call pytest-plugin,pytest-shell-utilities,shell-utilities))
$(eval $(call pytest-plugin,pytest-skip-markers,skip-markers))
$(eval $(call pytest-plugin,pytest-socket,socket))
$(eval $(call pytest-plugin,pytest-subprocess,pytest-subprocess))
$(eval $(call pytest-plugin,pytest-subtests,subtests))
$(eval $(call pytest-plugin,pytest-system-statistics,system-statistics))
$(eval $(call pytest-plugin,pytest-timeout,timeout))
$(eval $(call pytest-plugin,pytest-travis-fold,travis-fold))
$(eval $(call pytest-plugin,pytest-xdist,xdist))
$(eval $(call pytest-plugin,pytest-xdist,xdist.looponfail))
$(eval $(call pytest-plugin,pytest-xprocess,xprocess))
$(eval $(call pytest-plugin,teamcity-messages,pytest-teamcity))
$(eval $(call pytest-plugin,time-machine,time_machine))
$(eval $(call pytest-plugin,typeguard,typeguard))
#
# Transitional (indirect) runtime dependencies of pytest plugins.
#
# Note: The list is not exhaustive and contians only entries that proved to be
# needed or useful.
#
# pytest-datadir is required by pytest-regressions and pytest-regressions is required by coincidence
$(eval $(call pytest-plugin,coincidence,regressions))
$(eval $(call pytest-plugin,coincidence,pytest-datadir))

# By default disable all pytest plugins ...
COMPONENT_TEST_ENV += PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
# ... and load those in the PYTEST_PLUGINS list only.
# $(sort) is used to avoid duplicates and to strip spaces.
COMPONENT_TEST_ENV += PYTEST_PLUGINS="$(subst $(space),$(comma),$(sort $(PYTEST_PLUGINS)))"

# By default we are not interested in full list of test failures so exit on
# first failure to save time.  This could be easily overridden from environment
# if needed (for example to debug test failures) or in per-component Makefile.
PYTEST_FASTFAIL = -x
PYTEST_ADDOPTS += $(PYTEST_FASTFAIL)

# By default we are not interested to see the default long tracebacks.
# Detailed tracebacks are shown either for failures or xfails.  We aim to see
# testing passed so there should be no failures.  Since xfails are expected
# failures we are not interested in detailed tracebacks here at all since they
# could contain random data, like pointers, temporary file names, etc.
PYTEST_TRACEBACK = --tb=line
PYTEST_ADDOPTS += $(PYTEST_TRACEBACK)

# Normalize pytest test results.  The pytest framework could be used either
# directly or via tox or setup.py so add these transforms for all test styles
# unconditionally.
COMPONENT_TEST_TRANSFORMS += \
	"-e 's/^\(platform sunos5 -- Python \)$(shell echo $(PYTHON_VERSION) | $(GSED) -e 's/\./\\./g')\.[0-9]\{1,\}.*\( -- .*\)/\1\$$(PYTHON_VERSION).X\2/'"
COMPONENT_TEST_TRANSFORMS += "-e '/^plugins: /d'"				# order of listed plugins could vary
COMPONENT_TEST_TRANSFORMS += "-e '/^-\{1,\} coverage: /,/^$$/d'"		# remove coverage report
COMPONENT_TEST_TRANSFORMS += "-e 's/ \{1,\}\[...%\]\$$//'"			# drop percentage
COMPONENT_TEST_TRANSFORMS += \
	"-e 's/^=\{1,\} \(.*\) in [0-9]\{1,\}\.[0-9]\{1,\}s \(([^)]*) \)\?=\{1,\}$$/======== \1 ========/'"	# remove timing
# Remove slowest durations report for projects that run pytest with --durations option
COMPONENT_TEST_TRANSFORMS += "-e '/^=\{1,\} slowest [0-9 ]*durations =\{1,\}$$/,/^=/{/^=/!d}'"
# Remove short test summary info for projects that run pytest with -r option
COMPONENT_TEST_TRANSFORMS += "-e '/^=\{1,\} short test summary info =\{1,\}$$/,/^=/{/^=/!d}'"

# Normalize test results produced by pytest-benchmark
COMPONENT_TEST_TRANSFORMS += \
	$(if $(filter library/python/pytest-benchmark-$(subst .,,$(PYTHON_VERSION)), $(REQUIRED_PACKAGES) $(TEST_REQUIRED_PACKAGES)),"| ( \
		$(GSED) -e '/^-\{1,\} benchmark/,/^=/{/^=/!d}' \
	) | $(COMPONENT_TEST_TRANSFORMER) -e ''")

# Normalize test results produced by pytest-randomly
USE_PYTEST_RANDOMLY = $(filter library/python/pytest-randomly-$(subst .,,$(PYTHON_VERSION)), $(REQUIRED_PACKAGES) $(TEST_REQUIRED_PACKAGES))
PYTEST_SORT_TESTS = $(USE_PYTEST_RANDOMLY)
COMPONENT_TEST_TRANSFORMS += $(if $(strip $(USE_PYTEST_RANDOMLY)),"-e '/^Using --randomly-seed=[0-9]\{1$(comma)\}\$$/d'")
COMPONENT_TEST_TRANSFORMS += \
	$(if $(strip $(PYTEST_SORT_TESTS)),"| ( \
		$(GSED) -u -e '/^=\{1$(comma)\} test session starts /q' ; \
		$(GSED) -u -e '/^\$$/q' ; \
		$(GSED) -u -e '/^\$$/Q' | $(SORT) | $(GSED) -e '\$$a\'\$$'\\\n\\\n' ; \
		$(CAT) \
	) | $(COMPONENT_TEST_TRANSFORMER) -e ''")

# Normalize test results produced by pytest-xdist
COMPONENT_TEST_TRANSFORMS += \
	$(if $(filter library/python/pytest-xdist-$(subst .,,$(PYTHON_VERSION)), $(REQUIRED_PACKAGES) $(TEST_REQUIRED_PACKAGES)),"| ( \
		$(GSED) -u \
			-e '/^created: .* workers$$/d' \
			-e 's/^[0-9]\{1,\}\( workers \[[0-9]\{1,\} items\]\)$$/X\1/' \
			-e '/^scheduling tests via /q' ; \
		$(GSED) -u -e '/^$$/q' ; \
		$(GSED) -u -n -e '/^\[gw/p' -e '/^$$/Q' | ( $(GSED) \
			-e 's/^\[gw[0-9]\{1,\}\] \[...%\] //' \
			-e 's/ *$$//' \
			-e 's/\([^ ]\{1,\}\) \(.*\)$$/\2 \1/' \
			| $(SORT) | $(NAWK) '{print}END{if(NR>0)printf(\"\\\\n\")}' ; \
		) ; \
		$(CAT) \
	) | $(COMPONENT_TEST_TRANSFORMER) -e ''")

# Normalize stestr test results
USE_STESTR = $(filter library/python/stestr-$(subst .,,$(PYTHON_VERSION)), $(REQUIRED_PACKAGES) $(TEST_REQUIRED_PACKAGES))
COMPONENT_TEST_TRANSFORMS += \
	$(if $(strip $(USE_STESTR)),"| ( \
			$(GSED) -e '0,/^{[0-9]\{1,\}}/{//i\'\$$'\\\n{0}\\\n}' \
				-e 's/^\(Ran: [0-9]\{1,\} tests\{0,1\}\) in .*\$$/\1/' \
				-e '/^Sum of execute time for each test/d' \
				-e '/^ - Worker /d' \
		) | ( \
			$(GSED) -u -e '/^{0}\$$/Q' ; \
			$(GSED) -u -e 's/^{[0-9]\{1,\}} //' \
				-e 's/\[[.0-9]\{1,\}s\] \.\.\./.../' \
				-e '/^\$$/Q' | $(SORT) | $(GSED) -e '\$$a\'\$$'\\\n\\\n' ; \
			$(CAT) \
		) | $(COMPONENT_TEST_TRANSFORMER) -e ''")

# Remove timestamp produced by coincidence
USE_COINCIDENCE = $(filter library/python/coincidence-$(subst .,,$(PYTHON_VERSION)), $(REQUIRED_PACKAGES) $(TEST_REQUIRED_PACKAGES))
COMPONENT_TEST_TRANSFORMS += $(if $(strip $(USE_COINCIDENCE)),"-e '/^Test session started at/d'")

# Normalize setup.py test results.  The setup.py testing could be used either
# directly or via tox so add these transforms for all test styles
# unconditionally.
COMPONENT_TEST_TRANSFORMS += "-e '/SetuptoolsDeprecationWarning:/,+1d'"		# depends on Python version and is useless
COMPONENT_TEST_TRANSFORMS += "-e 's/^\(Ran [0-9]\{1,\} tests\{0,1\}\) in .*$$/\1/'"	# delete timing from test results

COMPONENT_TEST_DIR = $(@D)$(COMPONENT_SUBDIR:%=/%)

ifeq ($(strip $(SINGLE_PYTHON_VERSION)),no)
# Temporarily create symlinks for renamed binaries
COMPONENT_PRE_TEST_ACTION += \
	for f in $(PROTOUSRBINDIR)/*-$(PYTHON_VERSION) ; do \
		[ -f $$f ] || continue ; \
		[ -L $${f%%-$(PYTHON_VERSION)} ] && $(RM) $${f%%-$(PYTHON_VERSION)} ; \
		[ -e $${f%%-$(PYTHON_VERSION)} ] && continue ; \
		$(SYMLINK) $$(basename $$f) $${f%%-$(PYTHON_VERSION)} ; \
	done ;

# Cleanup of temporary symlinks
COMPONENT_POST_TEST_ACTION += \
	for f in $(PROTOUSRBINDIR)/*-$(PYTHON_VERSION) ; do \
		[ -f $$f ] || continue ; \
		[ ! -L $${f%%-$(PYTHON_VERSION)} ] || $(RM) $${f%%-$(PYTHON_VERSION)} ; \
	done ;
endif


ifeq ($(strip $(SINGLE_PYTHON_VERSION)),no)
# We need to add -$(PYV) to package fmri
GENERATE_EXTRA_CMD += | \
	$(GSED) -e 's/^\(set name=pkg.fmri [^@]*\)\(.*\)$$/\1-$$(PYV)\2/'
endif

# Add runtime dependencies from project metadata to generated manifest
GENERATE_EXTRA_DEPS += $(BUILD_DIR)/META.depend-runtime.res
GENERATE_EXTRA_CMD += | \
	$(CAT) - <( \
		echo "" ; \
		echo "\# python modules are unusable without python runtime binary" ; \
		echo "depend type=require fmri=__TBD pkg.debug.depend.file=python\$$(PYVER) \\" ; \
		echo "    pkg.debug.depend.path=usr/bin" ; \
		echo "" ; \
		echo "\# Automatically generated dependencies based on distribution metadata" ; \
		$(CAT) $(BUILD_DIR)/META.depend-runtime.res \
	)

# Add runtime dependencies from project metadata to REQUIRED_PACKAGES
REQUIRED_PACKAGES_RESOLVED += $(BUILD_DIR)/META.depend-runtime.res


# Generate raw lists of runtime dependencies per Python version
COMPONENT_POST_INSTALL_ACTION += \
	PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
		$(PYTHON) $(WS_TOOLS)/python-requires $(COMPONENT_NAME) >> $(@D)/.depend-runtime ;

# Convert raw per version lists of runtime dependencies to single resolved
# runtime dependency list.  The dependency on META.depend-test.required here is
# purely to get the file created as a side effect of this target.
$(BUILD_DIR)/META.depend-runtime.res:	$(INSTALL_$(MK_BITS)) $(BUILD_DIR)/META.depend-test.required
	$(CAT) $(INSTALL_$(MK_BITS):%.installed=%.depend-runtime) | $(SORT) -u \
		| $(GSED) -e 's/.*/depend type=require fmri=pkg:\/library\/python\/&-$$(PYV)/' > $@

# Generate raw lists of test dependencies per Python version
COMPONENT_POST_INSTALL_ACTION += \
	cd $(@D)$(COMPONENT_SUBDIR:%=/%) ; \
	( for f in $(TEST_REQUIREMENTS) ; do \
		$(CAT) $$f | $(DOS2UNIX) -ascii ; \
	done ; \
	for e in $(TEST_REQUIREMENTS_EXTRAS) ; do \
		PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
			$(PYTHON) $(WS_TOOLS)/python-requires $(COMPONENT_NAME) $$e ; \
	done ) | $(WS_TOOLS)/python-resolve-deps \
		PYTHONPATH=$(PROTO_DIR)/$(PYTHON_DIR)/site-packages:$(PROTO_DIR)/$(PYTHON_LIB) \
		$(PYTHON) $(WS_TOOLS)/python-requires $(COMPONENT_NAME) \
	| $(PYTHON) $(WS_TOOLS)/python-requires - >> $(@D)/.depend-test ;

# Convert raw per version lists of test dependencies to single list of
# TEST_REQUIRED_PACKAGES entries.  Some Python projects lists their own project
# as a test dependency so filter this out here too.
$(BUILD_DIR)/META.depend-test.required:	$(INSTALL_$(MK_BITS))
	$(CAT) $(INSTALL_$(MK_BITS):%.installed=%.depend-test) | $(SORT) -u \
		| $(GSED) -e 's/.*/TEST_REQUIRED_PACKAGES.python += library\/python\/&/' \
		| ( $(GNU_GREP) -v ' $(COMPONENT_FMRI)$$' || true ) \
		> $@

# Add META.depend-test.required to the generated list of REQUIRED_PACKAGES
REQUIRED_PACKAGES_TRANSFORM += -e '$$r $(BUILD_DIR)/META.depend-test.required'

# The python-requires script requires packaging to provide useful output but
# packaging might be unavailable during bootstrap until we reach bootstrap
# checkpoint 2.  So require it conditionally.
ifeq ($(filter $(strip $(COMPONENT_NAME)),$(PYTHON_BOOTSTRAP_CHECKPOINT_2)),)
USERLAND_REQUIRED_PACKAGES.python += library/python/packaging
endif


clean::
	$(RM) -r $(SOURCE_DIR) $(BUILD_DIR)

# Make it easy to construct a URL for a pypi source download.
pypi_url_multi = pypi:///$(COMPONENT_NAME_$(1))==$(COMPONENT_VERSION_$(1))
pypi_url_single = pypi:///$(COMPONENT_NAME)==$(COMPONENT_VERSION)
pypi_url = $(if $(COMPONENT_NAME_$(1)),$(pypi_url_multi),$(pypi_url_single))

# Use common rules
USE_COMMON_RULES = yes

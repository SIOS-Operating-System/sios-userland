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
# Copyright 2017,2022 Gary Mills
# Copyright (c) 2010, 2016, Oracle and/or its affiliates. All rights reserved.
#

# These symbols should be used in component Makefiles
# whenever PATH is to be defined there:
#     PATH = $(PATH.illumos)
#     PATH = $(PATH.gnu)
PATH.illumos =	$(subst $(space),:,$(strip $(PATH.prepend))):$(USRBINDIR$(BITS)):$(USRBINDIR):$(GNUBIN):$(USRSBINDIR$(BITS)):$(USRSBINDIR)
PATH.gnu =	$(subst $(space),:,$(strip $(PATH.prepend))):$(GNUBIN):$(USRBINDIR$(BITS)):$(USRBINDIR):$(USRSBINDIR$(BITS)):$(USRSBINDIR)

# Default PATH
PATH = $(PATH.illumos)

#
# Following settings should be done as soon as possible, even before the first
# $(shell) function invocation.
#
# We prefer bash as the shell
SHELL = /bin/bash
# Full paths to used tools
CUT = /usr/bin/cut
GETCONF = /usr/bin/getconf
GIT = /usr/bin/git
SHA1SUM = /usr/bin/sha1sum
TR = /usr/bin/tr
UNAME = /usr/bin/uname
WHICH = /usr/bin/which

# The location of an internal mirror of community source archives that we build
# in this gate.  This mirror has been seeded to include "custom" source archives
# for a few components where the communities either no longer provide matching
# source archives or we have changes that aren't reflected in their archives or
# anywhere else.
#INTERNAL_ARCHIVE_MIRROR =	http://userland.us.oracle.com/source-archives

# The location of an external mirror of community source archives that we build
# in this gate.  The external mirror is a replica of the internal mirror.
#EXTERNAL_ARCHIVE_MIRROR = \
#	http://static.opensolaris.org/action/browse/userland/tarball/userland

DLC_ARCHIVE_MIRROR = https://dlc.openindiana.org/oi-userland/source-archives

# Default to looking for source archives on the internal mirror and the external
# mirror before we hammer on the community source archive repositories.
#export DOWNLOAD_SEARCH_PATH +=	$(INTERNAL_ARCHIVE_MIRROR)
#export DOWNLOAD_SEARCH_PATH +=	$(EXTERNAL_ARCHIVE_MIRROR)

# Look for file at DLC server as last resort
export DOWNLOAD_FALLBACK_PATH =  $(DLC_ARCHIVE_MIRROR)

# The workspace starts at the git root
ifeq ($(origin WS_TOP), undefined)
export WS_TOP := \
	$(shell $(GIT) rev-parse --show-toplevel)
endif

USERLAND_ARCHIVES ?=	$(WS_TOP)/archives/
WS_MACH =       $(WS_TOP)/$(MACH)
WS_LOGS =       $(WS_MACH)/logs
WS_REPO =       $(WS_MACH)/repo
WS_TOOLS =      $(WS_TOP)/tools
WS_MAKE_RULES = $(WS_TOP)/make-rules
WS_COMPONENTS = $(WS_TOP)/components
WS_LICENSES =   $(WS_TOP)/licenses
WS_INCORPORATIONS =     $(WS_TOP)/incorporations
WS_LINT_CACHE = $(WS_MACH)/pkglint-cache

# we want our pkg piplines to fail if there is an error
# (like if pkgdepend fails in the middle of a pipe), but
# we don't want the builds or ./configure's failing as well.
# so we only set pipefail for the publish target and have
# to reset it for the others since they might be invoked
# as dependencies of publish.
export SHELLOPTS
build:		SHELLOPTS=
test:		SHELLOPTS=
install:	SHELLOPTS=
publish:	SHELLOPTS=pipefail

# This can be overridden to avoid rebuilding when you touch a Makefile
MAKEFILE_PREREQ =	Makefile

CONSOLIDATION =	userland
PUBLISHER ?=	$(CONSOLIDATION)
PUBLISHER_LOCALIZABLE ?=	$(CONSOLIDATION)-localizable

# Defines $(space) as a single blank space, so we can use it to convert
# space-separated paths to colon-separated paths in variables with
# $(subst $(space),:,$(strip $(SPATHS)))
empty :=
space := $(empty) $(empty)
# Define $(comma) as single comma so we can use it in text transforming functions
comma = ,
# Define $(newline) as single newline so we can embed newline into make variables
define newline


endef

ROOT =			/

# Distribution name and version
# Note, this determines /etc/release file contents.
# Some OI-specific software (like slim installer or openindiana-welcome) 
# currently rely on format of first line in this file
# to determine the distribution version
# (it should look like OpenIndiana Hipster YYYY.MM).
DISTRIBUTION_NAME = OpenIndiana Hipster
DISTRIBUTION_VERSION = 2024.10
# Native OS version
OS_VERSION :=		$(shell $(UNAME) -r)
SOLARIS_VERSION =	$(OS_VERSION:5.%=2.%)
# Target OS version
PKG_SOLARIS_VERSION ?= 5.11
PKG_OS_VERSION ?= 0.$(PKG_SOLARIS_VERSION)

# GNU target triplet
GNU_TRIPLET=$(GNU_CPU)-$(GNU_VENDOR)-$(GNU_OS)
# The cpu part of the triplet is this:
# i386/sparc     - for GCC version older than 9 - so same as $(MACH)
# x86_64/sparcv9 - for GCC version 9 and newer - $(MACH64) is close to this
GNU_CPU = $(if $(filter $(GCC_VERSION),3 7),$(MACH),$(MACH64:amd64=x86_64))
# The vendor part of the triplet is:
# pc - for x86
# sun - for SPARC
GNU_VENDOR.i386 = pc
GNU_VENDOR.sparc = sun
GNU_VENDOR = $(GNU_VENDOR.$(MACH))
# The os part of the triplet is solaris2.11
GNU_OS = solaris$(SOLARIS_VERSION)

include $(WS_MAKE_RULES)/ips-buildinfo.mk

COMPILER =		gcc
LINKER =		gcc

# The value of BITS is set automatically during the build process to either 32
# or 64 as needed.

# This macro makes it possible to determine which components are only built
# 64-bit (default) and allow other make-rules files to adjust accordingly.
# Possible values are: '32', '64', '32_and_64', '64_and_32', and 'NO_ARCH' (the
# orderings specify build preference).
BUILD_BITS ?= 64

# Based on BUILD_BITS, determine which binaries are preferred for a build.
# This macro is for the convenience of other make-rules files and should not be
# overridden by developers.
ifeq ($(strip $(BUILD_BITS)),64)
PREFERRED_BITS=64
endif
# Now we prefer 64-bit
ifeq ($(strip $(BUILD_BITS)),64_and_32)
PREFERRED_BITS=64
endif
PREFERRED_BITS ?= 32

# Map target build to macro/variable naming conventions.  This macro is for the
# convenience of other make-rules files and should not be overridden by
# developers.
ifeq ($(BUILD_BITS),64_and_32)
MK_BITS=32_and_64
else
MK_BITS=$(strip $(BUILD_BITS))
endif

#
# Upstream support for Python is by default 5 years after the first release.
# We will start to obsolete Python versions according the following table:
#
# +----------------+----------------+
# | Python version | Obsolete after |
# +----------------+----------------+
# |      3.9       |   2025-10      |
# +----------------+----------------+
#
# See https://devguide.python.org/versions/
#

PYTHON_VERSION = 3.9
PYTHON_VERSIONS = 3.9

# Python up to 2.7 was built both 32-bit and 64-bit.  Starting with Python 3.x
# the python package is built 64-bit only.  So now all PYTHON_VERSIONS are
# 64-bit only.
PYTHON_64_ONLY_VERSIONS = $(PYTHON_VERSIONS)

# List of python versions we are currently obsoleting.  We no longer build any
# packages for these python versions, but there still might be hanging some not
# obsoleted yet versioned packages built for PYTHON_VERSIONS_OBSOLETING python
# versions.  Or there is just the versioned runtime/python package still
# available.
#
# This list should be usually empty.  Intersection of
# PYTHON_VERSIONS_OBSOLETING and PYTHON_VERSIONS lists MUST be always empty.
PYTHON_VERSIONS_OBSOLETING = 2.7 3.7

# PYTHON3_SOABI variable defines the naming scheme
# of python3 extension libraries: cpython or abi3.
# Currently, most of the components use cpython naming scheme by default,
# only python/xattr and python/cryptography require abi3 naming.
PYTHON3_SOABI ?= cpython
ifeq ($(PYTHON3_SOABI),cpython)
PY3_CPYTHON_NAMING=
PY3_ABI3_NAMING=\#
else ifeq ($(PYTHON3_SOABI),abi3)
PY3_CPYTHON_NAMING=\#
PY3_ABI3_NAMING=
else
$(error "Invalid python naming scheme '$(PYTHON3_SOABI)' selected!")
endif

BASS_O_MATIC =	$(WS_TOOLS)/bass-o-matic

CLONEY =	$(WS_TOOLS)/cloney

CONFIG_SHELL =	/bin/bash

PKG_REPO =	file:$(WS_REPO)

COMPONENT =		$(COMPONENT_DIR:$(WS_TOP)/components/%=%)
HUMAN_VERSION ?=	$(COMPONENT_VERSION)
COMPONENT_SRC_NAME =	$(COMPONENT_NAME)

COMPONENT_LICENSE_FILE ?= $(COMPONENT_NAME).license

COMPONENT_DIR :=	$(shell pwd)
SOURCE_DIR =	$(COMPONENT_DIR)/$(COMPONENT_SRC)
BUILD_DIR =	$(COMPONENT_DIR)/build
PROTO_DIR =	$(BUILD_DIR)/prototype/$(MACH)

ARCHLIBSUBDIR32	=
ARCHLIBSUBDIR64	= $(MACH64)
ARCHLIBSUBDIR	= $(ARCHLIBSUBDIR$(BITS))

ETCDIR =		/etc
USRDIR =		/usr
BINDIR =		/bin
SBINDIR =		/sbin
LIBDIR =		/lib
LIBEXECDIR =		/libexec
VARDIR =		/var
KERNELDRVDIR =		/kernel/drv
KERNELDRVDIR32 =	/kernel/drv
KERNELDRVDIR64 =	/kernel/drv/$(MACH64)
USRBINDIR = 		$(USRDIR)/bin
USRBINDIR32 =		$(USRDIR)/bin/$(MACH32)
USRBINDIR64 =		$(USRDIR)/bin/$(MACH64)
USRSBINDIR = 		$(USRDIR)/sbin
USRSBINDIR32 =		$(USRDIR)/sbin/$(MACH32)
USRSBINDIR64 =		$(USRDIR)/sbin/$(MACH64)
USRLIBDIR = 		$(USRDIR)/lib
USRLIBDIR32 =		$(USRDIR)/lib
USRLIBDIR64 =		$(USRDIR)/lib/$(MACH64)
USRLIBEXECDIR =		$(USRDIR)/libexec
USRLIBEXECDIR32 =	$(USRDIR)/libexec
USRLIBEXECDIR64 =	$(USRDIR)/libexec/$(MACH64)
USRSHAREDIR =		$(USRDIR)/share
USRINCDIR = 		$(USRDIR)/include
USRSHARELOCALEDIR =	$(USRSHAREDIR)/locale
USRSHAREMANDIR =	$(USRSHAREDIR)/man
USRSHAREDOCDIR =	$(USRSHAREDIR)/doc
USRSHARELIBDIR =	$(USRSHAREDIR)/lib
USRSHAREMAN1DIR =	$(USRSHAREMANDIR)/man1
USRSHAREMAN1MDIR =	$(USRSHAREMANDIR)/man1m
USRSHAREMAN3DIR =	$(USRSHAREMANDIR)/man3
USRSHAREMAN4DIR =	$(USRSHAREMANDIR)/man4
USRSHAREMAN5DIR =	$(USRSHAREMANDIR)/man5
USRSHAREMAN7DIR =	$(USRSHAREMANDIR)/man7
USRSHAREMAN8DIR =	$(USRSHAREMANDIR)/man8
USRKERNELDRVDIR =	$(USRDIR)/kernel/drv
USRKERNELDRVDIR32 =	$(USRDIR)/kernel/drv
USRKERNELDRVDIR64 =	$(USRDIR)/kernel/drv/$(MACH64)

# The *.$(BITS) variables are different from those above (better suited for
# isaexec wrapper), and allow for default 32-bit vs. nondefault 64-bit setups
USRBINDIR.32 = 		$(USRBINDIR)
USRBINDIR.64 = 		$(USRBINDIR64)
USRSBINDIR.32 =		$(USRSBINDIR)
USRSBINDIR.64 =		$(USRSBINDIR64)
USRLIBDIR.32 = 		$(USRLIBDIR)
USRLIBDIR.64 = 		$(USRLIBDIR64)
USRLIBEXECDIR.32 =	$(USRLIBEXECDIR)
USRLIBEXECDIR.64 =	$(USRLIBEXECDIR64)
PROTOETCDIR =		$(PROTO_DIR)/$(ETCDIR)
PROTOETCSECDIR = 	$(PROTO_DIR)/$(ETCDIR)/security
PROTOUSRDIR =		$(PROTO_DIR)/$(USRDIR)
PROTOBINDIR =		$(PROTO_DIR)/$(BINDIR)
PROTOSBINDIR =		$(PROTO_DIR)/$(SBINDIR)
PROTOLIBDIR =		$(PROTO_DIR)/$(LIBDIR)
PROTOLIBEXECDIR =	$(PROTO_DIR)/$(LIBEXECDIR)
PROTOVARDIR =		$(PROTO_DIR)/$(VARDIR)
PROTOKERNELDRVDIR =  	$(PROTO_DIR)/$(KERNELDRVDIR)
PROTOKERNELDRVDIR32 =	$(PROTO_DIR)/$(KERNELDRVDIR32)
PROTOKERNELDRVDIR64 =	$(PROTO_DIR)/$(KERNELDRVDIR64)
PROTOUSRBINDIR =	$(PROTO_DIR)/$(USRBINDIR)
PROTOUSRBINDIR32 =	$(PROTO_DIR)/$(USRBINDIR32)
PROTOUSRBINDIR64 =	$(PROTO_DIR)/$(USRBINDIR64)
PROTOUSRSBINDIR =	$(PROTO_DIR)/$(USRSBINDIR)
PROTOUSRSBINDIR32 =	$(PROTO_DIR)/$(USRSBINDIR32)
PROTOUSRSBINDIR64 =	$(PROTO_DIR)/$(USRSBINDIR64)
PROTOUSRLIBDIR =	$(PROTO_DIR)/$(USRLIBDIR)
PROTOUSRLIBDIR32 =	$(PROTO_DIR)/$(USRLIBDIR32)
PROTOUSRLIBDIR64 =	$(PROTO_DIR)/$(USRLIBDIR64)
PROTOUSRLIBEXECDIR =	$(PROTO_DIR)/$(USRLIBEXECDIR)
PROTOUSRLIBEXECDIR32 =	$(PROTO_DIR)/$(USRLIBEXECDIR32)
PROTOUSRLIBEXECDIR64 =	$(PROTO_DIR)/$(USRLIBEXECDIR64)
PROTOUSRINCDIR =	$(PROTO_DIR)/$(USRINCDIR)
PROTOUSRSHAREDIR =	$(PROTO_DIR)/$(USRSHAREDIR)
PROTOUSRSHARELIBDIR =	$(PROTO_DIR)/$(USRSHARELIBDIR)
PROTOUSRSHAREMANDIR =	$(PROTO_DIR)/$(USRSHAREMANDIR)
PROTOUSRSHAREDOCDIR =	$(PROTO_DIR)/$(USRSHAREDOCDIR)
PROTOUSRSHAREMAN1DIR =	$(PROTO_DIR)/$(USRSHAREMAN1DIR)
PROTOUSRSHAREMAN1MDIR =	$(PROTO_DIR)/$(USRSHAREMAN1MDIR)
PROTOUSRSHAREMAN3DIR =	$(PROTO_DIR)/$(USRSHAREMAN3DIR)
PROTOUSRSHAREMAN4DIR =	$(PROTO_DIR)/$(USRSHAREMAN4DIR)
PROTOUSRSHAREMAN5DIR =	$(PROTO_DIR)/$(USRSHAREMAN5DIR)
PROTOUSRSHAREMAN8DIR =	$(PROTO_DIR)/$(USRSHAREMAN8DIR)
PROTOUSRSHARELOCALEDIR =	$(PROTO_DIR)/$(USRSHARELOCALEDIR)
PROTOUSRKERNELDRVDIR =  	$(PROTO_DIR)/$(USRKERNELDRVDIR)
PROTOUSRKERNELDRVDIR32 =	$(PROTO_DIR)/$(USRKERNELDRVDIR32)
PROTOUSRKERNELDRVDIR64 =	$(PROTO_DIR)/$(USRKERNELDRVDIR64)

PROTOUSRBINDIR.32 = 	$(PROTOUSRBINDIR)
PROTOUSRBINDIR.64 = 	$(PROTOUSRBINDIR64)
PROTOUSRSBINDIR.32 =	$(PROTOUSRSBINDIR)
PROTOUSRSBINDIR.64 =	$(PROTOUSRSBINDIR64)
PROTOUSRLIBDIR.32 = 	$(PROTOUSRLIBDIR)
PROTOUSRLIBDIR.64 = 	$(PROTOUSRLIBDIR64)
PROTOUSRLIBEXECDIR.32 = $(PROTOUSRLIBEXECDIR)
PROTOUSRLIBEXECDIR.64 = $(PROTOUSRLIBEXECDIR64)

# NOTE: We do not build SFW contents
# /usr/sfw/bin is just a historic artefact, containing symlinks
SFWBIN =	/usr/sfw/bin
SFWBIN32 =	$(SFWBIN)
SFWBIN64 =	$(SFWBIN)/$(MACH64)
SFWSBIN =	/usr/sfw/sbin
SFWSBIN32 =	$(SFWSBIN)
SFWSBIN64 =	$(SFWSBIN)/$(MACH64)
SFWINCLUDE =	/usr/sfw/include
SFWLIB =	/usr/sfw/lib
SFWLIB32 =	$(SFWLIB)
SFWLIB64 =	$(SFWLIB)/$(MACH64)
SFWSHARE =	/usr/sfw/share
SFWSHAREMAN =	$(SFWSHARE)/man
SFWSHAREMAN1 =	$(SFWSHAREMAN)/man1
PROTOSFWBIN =   	$(PROTO_DIR)/$(SFWBIN)
PROTOSFWBIN32 = 	$(PROTO_DIR)/$(SFWBIN32)
PROTOSFWBIN64 = 	$(PROTO_DIR)/$(SFWBIN64)
PROTOSFWSBIN =  	$(PROTO_DIR)/$(SFWSBIN)
PROTOSFWSBIN32 =	$(PROTO_DIR)/$(SFWSBIN32)
PROTOSFWSBIN64 =	$(PROTO_DIR)/$(SFWSBIN64)
PROTOSFWLIB =	$(PROTO_DIR)/$(SFWLIB)
PROTOSFWLIB32 =	$(PROTO_DIR)/$(SFWLIB32)
PROTOSFWLIB64 =	$(PROTO_DIR)/$(SFWLIB64)
PROTOSFWSHARE =	$(PROTO_DIR)/$(SFWSHARE)
PROTOSFWSHAREMAN =	$(PROTO_DIR)/$(SFWSHAREMAN)
PROTOSFWSHAREMAN1 =	$(PROTO_DIR)/$(SFWSHAREMAN1)
PROTOSFWINCLUDE =	$(PROTO_DIR)/$(SFWINCLUDE)

# The *.$(BITS) variables are different from those above (better suited for
# isaexec wrapper), and allow for default 32-bit vs. nondefault 64-bit setups
SFWBIN.32 = 	$(SFWBIN)
SFWBIN.64 = 	$(SFWBIN64)
SFWSBIN.32 =	$(SFWSBIN)
SFWSBIN.64 =	$(SFWSBIN64)
SFWLIB.32 = 	$(SFWLIB)
SFWLIB.64 = 	$(SFWLIB64)
PROTOSFWBIN.32 =	$(PROTOSFWBIN)
PROTOSFWBIN.64 =	$(PROTOSFWBIN64)
PROTOSFWSBIN.32 =	$(PROTOSFWSBIN)
PROTOSFWSBIN.64 =	$(PROTOSFWSBIN64)
PROTOSFWLIB.32 =	$(PROTOSFWLIB)
PROTOSFWLIB.64 =	$(PROTOSFWLIB64)

CLDIR =	/usr/share/common-lisp
PROTOCLDIR =	$(PROTO_DIR)/$(CLDIR)

GNUDIR =	/usr/gnu
GNUBIN =	$(GNUDIR)/bin
GNUBIN32 =	$(GNUBIN)/$(MACH32)
GNUBIN64 =	$(GNUBIN)/$(MACH64)
GNUSBIN =	$(GNUDIR)/sbin
GNUSBIN32 =	$(GNUSBIN)/$(MACH32)
GNUSBIN64 =	$(GNUSBIN)/$(MACH64)
GNULIB =	$(GNUDIR)/lib
GNULIB32 =	$(GNULIB)
GNULIB64 =	$(GNULIB)/$(MACH64)
GNUSHARE =	$(GNUDIR)/share
GNUSHAREMAN =	$(GNUSHARE)/man
GNUSHAREMAN1 =	$(GNUSHAREMAN)/man1
PROTOGNUBIN =   	$(PROTO_DIR)/$(GNUBIN)
PROTOGNUBIN32 = 	$(PROTO_DIR)/$(GNUBIN32)
PROTOGNUBIN64 = 	$(PROTO_DIR)/$(GNUBIN64)
PROTOGNUSBIN =  	$(PROTO_DIR)/$(GNUSBIN)
PROTOGNUSBIN32 =	$(PROTO_DIR)/$(GNUSBIN32)
PROTOGNUSBIN64 =	$(PROTO_DIR)/$(GNUSBIN64)
PROTOGNULIB =   	$(PROTO_DIR)/$(GNULIB)
PROTOGNULIB32 = 	$(PROTO_DIR)/$(GNULIB32)
PROTOGNULIB64 = 	$(PROTO_DIR)/$(GNULIB64)
PROTOGNUSHARE = 	$(PROTO_DIR)/$(GNUSHARE)
PROTOGNUSHAREMAN =	$(PROTO_DIR)/$(GNUSHAREMAN)
PROTOGNUSHAREMAN1 =	$(PROTO_DIR)/$(GNUSHAREMAN1)

# The *.$(BITS) variables are different from those above (better suited for
# isaexec wrapper), and allow for default 32-bit vs. nondefault 64-bit setups
GNUBIN.32 = 	$(GNUBIN)
GNUBIN.64 = 	$(GNUBIN64)
GNUSBIN.32 =	$(GNUSBIN)
GNUSBIN.64 =	$(GNUSBIN64)
GNULIB.32 = 	$(GNULIB)
GNULIB.64 = 	$(GNULIB64)
PROTOGNUBIN.32 =	$(PROTOGNUBIN)
PROTOGNUBIN.64 =	$(PROTOGNUBIN64)
PROTOGNUSBIN.32 =	$(PROTOGNUSBIN)
PROTOGNUSBIN.64 =	$(PROTOGNUSBIN64)
PROTOGNULIB.32 =	$(PROTOGNULIB)
PROTOGNULIB.64 =	$(PROTOGNULIB64)

# work around _TIME, _DATE, embedded date chatter in component builds
# to use, set TIME_CONSTANT in the component Makefile and add $(CONSTANT_TIME)
# to the appropriate {CONFIGURE|BUILD|INSTALL}_ENV
CONSTANT_TIME =		LD_PRELOAD_32=$(WS_TOOLS)/time-$(MACH32).so
CONSTANT_TIME +=	LD_PRELOAD_64=$(WS_TOOLS)/time-$(MACH64).so
CONSTANT_TIME +=	TIME_CONSTANT=$(TIME_CONSTANT)

# List known architectures
MACH_LIST = sparc i386

# set MACH from uname -p to either sparc or i386
MACH :=		$(shell $(UNAME) -p)

# set MACH32 from MACH to either sparcv7 or i86
MACH32_1 =	$(MACH:sparc=sparcv7)
MACH32 =	$(MACH32_1:i386=i86)

# set MACH64 from MACH to either sparcv9 or amd64
MACH64_1 =	$(MACH:sparc=sparcv9)
MACH64 =	$(MACH64_1:i386=amd64)

CONFIGURE_NO_ARCH =	$(BUILD_DIR_NO_ARCH)/.configured
CONFIGURE_32 =		$(BUILD_DIR_32)/.configured
CONFIGURE_64 =		$(BUILD_DIR_64)/.configured

BUILD_DIR_NO_ARCH =	$(BUILD_DIR)/$(MACH)
BUILD_DIR_32 =		$(BUILD_DIR)/$(MACH32)
BUILD_DIR_64 =		$(BUILD_DIR)/$(MACH64)

BUILD_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.built
BUILD_32 =		$(BUILD_DIR_32)/.built
BUILD_64 =		$(BUILD_DIR_64)/.built
BUILD_32_and_64 =	$(BUILD_32) $(BUILD_64)
$(BUILD_DIR_NO_ARCH)/.built:	BITS=32
$(BUILD_DIR_32)/.built:		BITS=32
$(BUILD_DIR_64)/.built:		BITS=64

INSTALL_NO_ARCH =	$(BUILD_DIR_NO_ARCH)/.installed
INSTALL_32 =		$(BUILD_DIR_32)/.installed
INSTALL_64 =		$(BUILD_DIR_64)/.installed
INSTALL_32_and_64 =	$(INSTALL_32) $(INSTALL_64)
$(BUILD_DIR_32)/.installed:       BITS=32
$(BUILD_DIR_64)/.installed:       BITS=64
# If we are building both 32 and 64 bit then make sure we install in the
# desired order: the preferred one last
ifeq ($(strip $(BUILD_BITS)),64_and_32)
$(INSTALL_64):	$(INSTALL_32)
endif
ifeq ($(strip $(BUILD_BITS)),32_and_64)
$(INSTALL_32):	$(INSTALL_64)
endif

# set the default target for installation of the component
COMPONENT_INSTALL_TARGETS =	install

# set the default build test results directory
COMPONENT_TEST_BUILD_DIR =	$(BUILD_DIR)/test/$(MACH$(BITS))

# set the default master test results directory
COMPONENT_TEST_RESULTS_DIR =	$(COMPONENT_DIR)/test

# set the default master test results file
USE_COMMON_TEST_MASTER ?= yes
ifeq ($(strip $(USE_COMMON_TEST_MASTER)),yes)
COMPONENT_TEST_MASTER =		$(COMPONENT_TEST_RESULTS_DIR)/results-all.master
else
COMPONENT_TEST_MASTER =		$(COMPONENT_TEST_RESULTS_DIR)/results-$(BITS).master
endif

# set the default test results output file
COMPONENT_TEST_OUTPUT =		$(COMPONENT_TEST_BUILD_DIR)/test-$(BITS)-results

# set the default test results comparison diffs file
COMPONENT_TEST_DIFFS =		$(COMPONENT_TEST_BUILD_DIR)/test-$(BITS)-diffs

# set the default test snapshot file
COMPONENT_TEST_SNAPSHOT =	$(COMPONENT_TEST_BUILD_DIR)/results-$(BITS).snapshot

# Normally $(GSED) is simplest, but some results files need more power.
COMPONENT_TEST_TRANSFORMER =	$(GSED)

# The set of default transforms to be applied to the test results to try
# to normalize them.
COMPONENT_TEST_TRANSFORMS = \
	'-e "s|$(@D)|\\$$(@D)|g" ' \
	'-e "s|$(PERL)|\\$$(PERL)|g" ' \
	'-e "s|$(PYTHON)|\\$$(PYTHON)|g" ' \
	'-e "s|$(SOURCE_DIR)|\\$$(SOURCE_DIR)|g" '
COMPONENT_TEST_TRANSFORMS +=	"-e 's|$(PROTO_DIR)|\$$(PROTO_DIR)|g'"
COMPONENT_TEST_TRANSFORMS +=	"-e 's|$(BUILD_DIR)|\$$(BUILD_DIR)|g'"

# set the default commands used to generate the file containing the set
# of transforms to be applied to the test results to try to normalize them.
COMPONENT_TEST_CREATE_TRANSFORMS = \
	print "\#!/bin/sh" > $(COMPONENT_TEST_TRANSFORM_CMD); \
	print '$(CAT) $(COMPONENT_TEST_OUTPUT) | \\' \
		>> $(COMPONENT_TEST_TRANSFORM_CMD); \
	print '$(COMPONENT_TEST_TRANSFORMER) ' \
		$(COMPONENT_TEST_TRANSFORMS) \
		' \\' >> $(COMPONENT_TEST_TRANSFORM_CMD); \
	print '> $(COMPONENT_TEST_SNAPSHOT)' \
		>> $(COMPONENT_TEST_TRANSFORM_CMD); \

# set the default command for performing any test result munging
COMPONENT_TEST_TRANSFORM_CMD =	$(COMPONENT_TEST_BUILD_DIR)/transform-$(BITS)-results

# set the default operation to run to perform test result normalization
COMPONENT_TEST_PERFORM_TRANSFORM = \
	$(SHELL) $(COMPONENT_TEST_TRANSFORM_CMD); \

# set the default command used to compare the master results with the snapshot
COMPONENT_TEST_COMPARE_CMD =	$(GDIFF) -uNb

# set the default way that master and snapshot test results are compared
COMPONENT_TEST_COMPARE = \
	[ -e $(COMPONENT_TEST_MASTER) ] || exit 1; \
	$(COMPONENT_TEST_COMPARE_CMD) \
		$(COMPONENT_TEST_MASTER) $(COMPONENT_TEST_SNAPSHOT) \
		> $(COMPONENT_TEST_DIFFS); \
	print "Test results in $(COMPONENT_TEST_OUTPUT)"; \
	if [ -s $(COMPONENT_TEST_DIFFS) ]; \
	then \
		print "Differences found."; \
		$(CAT) $(COMPONENT_TEST_DIFFS); \
		exit 2; \
	else \
		print "No differences found."; \
	fi

# set the default env command to use for test of the component
COMPONENT_TEST_ENV_CMD =	$(ENV)

# set the default command to use for test of the component
COMPONENT_TEST_CMD =	$(GMAKE)

# set the default target for test of the component
COMPONENT_TEST_TARGETS =	check

# set the default directory for test of the component
COMPONENT_TEST_DIR =	$(@D)

# prepare the testing environment before we run tests
COMPONENT_TEST_DEP += component-test-environment-prep
# we test built components
COMPONENT_TEST_DEP += $(BUILD_DIR)/%/.built

# determine the type of tests we want to run.
ifeq ($(strip $(wildcard $(COMPONENT_TEST_RESULTS_DIR)/results-*.master)),)
TEST_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.tested
TEST_32 =		$(BUILD_DIR_32)/.tested
TEST_64 =		$(BUILD_DIR_64)/.tested
else
TEST_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.tested-and-compared
TEST_32 =		$(BUILD_DIR_32)/.tested-and-compared
TEST_64 =		$(BUILD_DIR_64)/.tested-and-compared
endif
TEST_32_and_64 =	$(TEST_32) $(TEST_64)

$(BUILD_DIR_NO_ARCH)/.tested-and-compared: BITS=32
$(BUILD_DIR_32)/.tested:		BITS=32
$(BUILD_DIR_64)/.tested:		BITS=64
$(BUILD_DIR_32)/.tested-and-compared:	BITS=32
$(BUILD_DIR_64)/.tested-and-compared:	BITS=64

# BUILD_TOOLS is the root of all tools not normally installed on the system.
BUILD_TOOLS ?=	/opt

#
# The CCACHE makefile variable should evaluate to empty string or a pathname
# like /usr/bin/ccache depending on your PATH value and "which" implementation.
# The assignment via ":=" is important, to only do this once in a Makefile,
# and not on every reference to the value as "=" assignment would result in.
# Review `man ccache` for optional configuration tuning, like cache size etc.
#
# For production builds or suspected errors you can disable this feature by
# setting ENABLE_CCACHE=false (as makefile or environment variable, which
# is currently the default) to not even define the usage of wrapper in the
# userland-building makefile system.
# If you want to speed up your re-builds, you must set ENABLE_CCACHE=true.
# For legacy reasons, the CCACHE_DISABLE and CCACHE_NODISABLE variables (from
# configuration of the "ccache" program itself) are also supported, but direct
# use is discouraged, since their syntax and usage are counter-intuitive.
#
# Still, absence of ccache in PATH is not considered a fatal error since the
# build would just proceed well with original compiler.
# Note: In code below we fast-track if the makefile CCACHE variable is defined
# but fall back to shell executability tests if just envvar CCACHE is passed.
#
export CCACHE := $(shell \
    if test -n "$(CCACHE)" ; then \
        echo "$(CCACHE)"; \
    else \
        if test x"$${CCACHE_DISABLE-}" != x -o x"$(CCACHE_DISABLE)" != x \
             -o x"$${ENABLE_CCACHE-}" = xfalse -o x"$(ENABLE_CCACHE)" = xfalse \
        ; then \
                echo "NOT USING CCACHE FOR OI-USERLAND because explicitly disabled" >&2 ; \
        else \
            if test x"$${CCACHE_NODISABLE-}" != x -o x"$(CCACHE_NODISABLE)" != x \
                 -o x"$${ENABLE_CCACHE-}" = xtrue -o x"$(ENABLE_CCACHE)" = xtrue \
            ; then \
                for F in \
                    "$$CCACHE" \
                    `$(WHICH) ccache 2>/dev/null | egrep '^/'` \
                    /usr/bin/ccache \
                ; do if test -n "$$F" && test -x "$$F" ; then \
                        echo "$$F" ; \
                        echo "USING CCACHE FOR OI-USERLAND: $$F" >&2 ; \
                        if test x"$${CCACHE_DISABLE-}" != x ; then \
                            echo "WARNING: envvar CCACHE_DISABLE is set, so effectively ccache will not act!" >&2 ; \
                        fi; \
                        exit 0; \
                    fi; \
                done; \
                echo "NOT USING CCACHE FOR OI-USERLAND because not found" >&2 ; \
            fi; \
        fi; \
    fi)

GCC_DEFAULT =	14
GCC_VERSION ?=	$(GCC_DEFAULT)
GCC_ROOT =	/usr/gcc/$(GCC_VERSION)

# If a component asked for non-default gcc version we need to make sure it is
# installed
USERLAND_REQUIRED_PACKAGES += $(if $(filter-out $(GCC_DEFAULT),$(GCC_VERSION)),developer/gcc-$(GCC_VERSION))

# Define runtime package names to be used in dependencies
GCC_RUNTIME_PKG =	system/library/gcc-$(GCC_VERSION)-runtime
GXX_RUNTIME_PKG =	system/library/g++-$(GCC_VERSION)-runtime
GCCGO_RUNTIME_PKG =	system/library/gccgo-$(GCC_VERSION)-runtime
GFORTRAN_RUNTIME_PKG =	system/library/gfortran-$(GCC_VERSION)-runtime
GOBJC_RUNTIME_PKG =	system/library/gobjc-$(GCC_VERSION)-runtime

CC.gcc.32 =	$(GCC_ROOT)/bin/gcc
CXX.gcc.32 =	$(GCC_ROOT)/bin/g++
F77.gcc.32 =	$(GCC_ROOT)/bin/gfortran
FC.gcc.32 =	$(GCC_ROOT)/bin/gfortran

CC.gcc.64 =	$(GCC_ROOT)/bin/gcc
CXX.gcc.64 =	$(GCC_ROOT)/bin/g++
F77.gcc.64 =	$(GCC_ROOT)/bin/gfortran
FC.gcc.64 =	$(GCC_ROOT)/bin/gfortran

# GCC directory macros
GCC_FULL_VERSION = $(shell $(GCC_ROOT)/bin/gcc -dumpversion)
GCC_GNU_TRIPLET  = $(GNU_TRIPLET)
GCC_BINDIR =	$(GCC_ROOT)/bin
GCC_LIBDIR.32 =	$(GCC_ROOT)/lib
GCC_LIBDIR.64 =	$(GCC_ROOT)/lib/$(MACH64)
GCC_LIBDIR =	$(GCC_LIBDIR.$(BITS))
GCC_INCDIR =	$(GCC_ROOT)/include
GCC_LIBGCCDIR =	$(GCC_ROOT)/lib/gcc
GCC_INCGXXDIR =	$(GCC_ROOT)/include/c++/$(GCC_FULL_VERSION)
PATH.prepend +=	$(GCC_BINDIR)

ifneq ($(strip $(CCACHE)),)

CCACHE_WRAP_ROOT   =	$(WS_TOOLS)/ccache-wrap
export CC_gcc_32  :=	$(CC.gcc.32)
export CC_gcc_64  :=	$(CC.gcc.64)
export CXX_gcc_32 :=	$(CXX.gcc.32)
export CXX_gcc_64 :=	$(CXX.gcc.64)
CC.gcc.32  :=	$(CCACHE_WRAP_ROOT)/CC.gcc.32
CC.gcc.64  :=	$(CCACHE_WRAP_ROOT)/CC.gcc.64
CXX.gcc.32 :=	$(CCACHE_WRAP_ROOT)/CXX.gcc.32
CXX.gcc.64 :=	$(CCACHE_WRAP_ROOT)/CXX.gcc.64

ifneq ($(strip $(CCACHE_DIR)),)
export CCACHE_DIR :=	$(CCACHE_DIR)
endif

ifneq ($(strip $(CCACHE_LOGFILE)),)
export CCACHE_LOGFILE :=	$(CCACHE_LOGFILE)
endif

endif

LD =		/usr/bin/ld

# Clang definitions (we only have 64 bit clang)
CLANG_DEFAULT =		19
CLANG_VERSION ?=	$(CLANG_DEFAULT)
CLANG_PREFIX =		/usr/clang/$(CLANG_VERSION)
CLANG_BINDIR =		$(CLANG_PREFIX)/bin
CLANG_LIBDIR             = $(CLANG_PREFIX)/lib
CLANG_DEVELOPER_PKG      = developer/clang-$(CLANG_VERSION)
CLANG_RUNTIME_PKG        = runtime/clang-$(CLANG_VERSION)
REQUIRED_PACKAGES_SUBST += CLANG_DEVELOPER_PKG
REQUIRED_PACKAGES_SUBST += CLANG_RUNTIME_PKG
PATH.prepend +=		$(CLANG_BINDIR)

# If a component asked for non-default clang version we need to make sure it is
# installed.  The clang component is an exception because its CLANG_VERSION
# often does not match the CLANG_DEFAULT and it does not need any clang for
# building (clang is built using gcc).
USERLAND_REQUIRED_PACKAGES += $(if $(filter-out clang,$(COMPONENT_NAME)), \
	$(if $(filter-out $(CLANG_DEFAULT),$(CLANG_VERSION)),$(CLANG_DEVELOPER_PKG)))

# Python definitions
PYTHON.3.9.VENDOR_PACKAGES.64 = /usr/lib/python3.9/vendor-packages
PYTHON.3.9.VENDOR_PACKAGES.32 = /usr/lib/python3.9/vendor-packages
PYTHON.3.9.VENDOR_PACKAGES = $(PYTHON.3.9.VENDOR_PACKAGES.$(BITS))

CC =		$(CC.$(COMPILER).$(BITS))
CXX =		$(CXX.$(COMPILER).$(BITS))
F77 =		$(F77.$(COMPILER).$(BITS))
FC =		$(FC.$(COMPILER).$(BITS))

#
# We will start to obsolete major Ruby versions according the following table:
#
# +--------------+----------------+
# | Ruby version | Obsolete after |
# +--------------+----------------+
# |     2.3      |   2019-03-31   |
# |     3.2      |   2026-03-31   |
# |     3.4      |   TBD          |
# +--------------+----------------+
#
# See https://www.ruby-lang.org/en/downloads/branches/
#

RUBY_VERSION = 3.2

RUBY_LIB_VERSION.2.3 = 2.3.0
RUBY_LIB_VERSION.3.2 = 3.2.0

RUBY_PREFIX = /usr/ruby/$(RUBY_VERSION)
RUBY = $(RUBY_PREFIX)/bin/ruby
RUBY_LIBDIR = $(RUBY_PREFIX)/lib/$(MACH64)
RUBY_LIB_VERSION = $(RUBY_LIB_VERSION.$(RUBY_VERSION))
PATH.prepend += $(RUBY_PREFIX)/bin

# Transform Ruby scripts to call the supported
# version-specific ruby; used in multiple *.mk files
RUBY_SCRIPT_FIX_FUNC = \
    $(GNU_GREP) -Rl '^\#! */usr/bin/env ruby' | \
        /usr/bin/xargs -I\{\} $(GSED) -i -e \
        '1s%^\#! */usr/bin/env ruby%\#!/usr/ruby/$(RUBY_VERSION)/bin/ruby%' \
        \{\}

# Use the ruby lib versions to represent the RUBY_VERSIONS that
# need to get built.  This is done because during package transformations
# both the ruby version and the ruby library version are needed.
RUBY_VERSIONS = $(RUBY_LIB_VERSION)

PYTHON_VENDOR_PACKAGES.32 = $(PYTHON.$(PYTHON_VERSION).VENDOR_PACKAGES.32)
PYTHON_VENDOR_PACKAGES.64 = $(PYTHON.$(PYTHON_VERSION).VENDOR_PACKAGES.64)
PYTHON_VENDOR_PACKAGES = $(PYTHON_VENDOR_PACKAGES.$(BITS))

# python2 was built for both 32- and 64-bits.
# python3 is built for 64-bits only.

PYTHON.3.9 =	/usr/bin/python3.9
PYTHON.3.9.64 =	$(PYTHON.3.9)

PYTHON.64 =	$(PYTHON.$(PYTHON_VERSION).64)
PYTHON =	$(PYTHON.$(PYTHON_VERSION))

TOX.3.9 =	/usr/bin/tox-3.9
TOX =		$(TOX.$(PYTHON_VERSION))

# The default is site-packages, but that directory belongs to the end-user.
# Modules which are shipped by the OS but not with the core Python distribution
# belong in vendor-packages.
PYTHON_DIR= /usr/lib/python$(PYTHON_VERSION)
PYTHON_LIB= $(PYTHON_DIR)/vendor-packages
PYTHON_DATA= $(PYTHON_LIB)

# If the component has python scripts then the first line should probably
# point at the python version currently set by the $(PYTHON) variable so
# as not to be influenced by the ips python mediator.
# In the component's Makefile define PYTHON_SCRIPTS with a list of files
# to be edited.

# Edit the leading #!/usr/bin/python line in python scripts to use the
# BUILD's $(PYTHON). The source file must be recompiled after that, as
# the corresponding .pyc file is outdated now.
PYTHON_SCRIPT_SHEBANG_FIX_FUNC = \
    $(GSED) -i \
        -e '1s@/usr/bin/python3\{0,1\}$$@$(PYTHON)@' \
        -e '1s@/usr/bin/python3\{0,1\} @$(PYTHON) @' \
        -e '1s@/usr/bin/env python3\.[0-9]\{1,\}@$(PYTHON)@' \
        -e '1s@/usr/bin/env python3\{0,1\}@$(PYTHON)@' \
	$(PROTO_DIR)/$(1); \
    $(PYTHON) -m compileall $(PROTO_DIR)/$(1);

# PYTHON_SCRIPTS is a list of files from the calling Makefile.
PYTHON_SCRIPTS_PROCESS= \
    $(foreach s,$(PYTHON_SCRIPTS), \
            $(call PYTHON_SCRIPT_SHEBANG_FIX_FUNC,$(s)))

# Finally if PYTHON_SCRIPTS is defined in a Makefile then process them here.
# If multiple installs in the component then clear
# COMPONENT_POST_INSTALL_ACTION =
# and re-add $(PYTHON_SCRIPTS_PROCESS)
COMPONENT_POST_INSTALL_ACTION += $(PYTHON_SCRIPTS_PROCESS)


# JAVA_DEFAULT should be always set to the latest LTS version
JAVA_DEFAULT = 21
JAVA_VERSION ?= $(JAVA_DEFAULT)
JAVA_HOME = /usr/jdk/openjdk$(JAVA_VERSION)
PATH.prepend += $(JAVA_HOME)/bin

# JAVA8_HOME and JAVA11_HOME are kept for backward compatibility and should be
# removed once they are no longer used.
#
# Components should set JAVA_VERSION and use JAVA_HOME instead.
JAVA8_HOME =	/usr/jdk/openjdk8
JAVA11_HOME =	/usr/jdk/openjdk11

# If a component asked for non-default java version we need to make sure it is
# installed
USERLAND_REQUIRED_PACKAGES += $(if $(filter-out $(JAVA_DEFAULT),$(JAVA_VERSION)),runtime/java/openjdk$(JAVA_VERSION))


# QT macros
# We deliver version 5 in 32- and 64-bit variants.
QT5_VERSION = 5.15
QT5_BASEDIR = $(USRLIBDIR)/qt/$(QT5_VERSION)
QT5_BINDIR.32 = $(QT5_BASEDIR)/bin
QT5_LIBDIR.32 = $(QT5_BASEDIR)/lib
QT5_BINDIR.64 = $(QT5_BASEDIR)/bin/$(MACH64)
QT5_LIBDIR.64 = $(QT5_BASEDIR)/lib/$(MACH64)
QT5_BINDIR = $(QT5_BINDIR.$(BITS))
QT5_LIBDIR = $(QT5_LIBDIR.$(BITS))
QT5_INCDIR = $(QT5_BASEDIR)/include
QT5_PKG_CONFIG_PATH = $(QT5_LIBDIR)/pkgconfig

# We deliver version 6 only in a 64-bit variant.
QT6_VERSION = 6.6
QT6_BASEDIR = $(USRLIBDIR)/qt/$(QT6_VERSION)
QT6_BINDIR = $(QT6_BASEDIR)/bin/$(MACH64)
QT6_LIBDIR = $(QT6_BASEDIR)/lib/$(MACH64)
QT6_PKG_CONFIG_PATH = $(QT6_LIBDIR)/pkgconfig

#
# Upstream officially supports two recent major Perl versions.  They also aim
# to provide critical security fixes for major Perl versions whose 5.x.0
# release was within the past three years.
#
# We support union of both sets.  IOW, we will start to obsolete a major Perl
# version if its 5.x.0 was released longer than three years ago AND there are
# already released two newer major Perl versions.
#
# See https://perldoc.perl.org/perlpolicy
#
#
# We will start to obsolete major Perl versions according the following table:
#
# +--------------+----------------+
# | Perl version | Obsolete after |
# +--------------+----------------+
# |     5.36     |   2025-05-28   |
# |     5.38     |   2026-07-02   |
# |     5.40     |   2027-06-09   |
# +--------------+----------------+
#
# See https://www.cpan.org/src/README.html
#

# This is the default version of Perl
PERL_VERSION =  5.40

# The PERL_VERSIONS list should always be in ascending order (newest version
# last)
PERL_VERSIONS = 5.36 5.38 5.40
# Perl up to 5.22 was built 32-bit only.  Starting with 5.24 the perl package
# is built 64-bit only.  So now all PERL_VERSIONS are 64-bit only.
PERL_64_ONLY_VERSIONS = $(PERL_VERSIONS)

# List of perl versions we are currently obsoleting.  We no longer build any
# packages for these perl versions, but there still might be hanging some not
# obsoleted yet versioned packages built for PERL_VERSIONS_OBSOLETING perl
# versions.  Or there is just the versioned runtime/perl package still
# available.
#
# This list should be usually empty.  Intersection of PERL_VERSIONS_OBSOLETING
# and PERL_VERSIONS lists MUST be always empty.
PERL_VERSIONS_OBSOLETING =

define perl-path-rule
PERL.$(1) =		/usr/perl5/$(1)/bin/perl
POD2MAN.$(1) =		/usr/perl5/$(1)/bin/pod2man
PERL5BINDIR.$(1) =	/usr/perl5/$(1)/bin
endef
$(foreach perlver,$(PERL_VERSIONS),$(eval $(call perl-path-rule,$(perlver))))

PERL5BINDIR = 	$(PERL5BINDIR.$(PERL_VERSION))
PERL =		$(PERL.$(PERL_VERSION))
POD2MAN =	$(POD2MAN.$(PERL_VERSION))

PERL_ARCH =	$(shell $(PERL) -e 'use Config; print $$Config{archname}')
PERL_ARCH_FUNC=	$(shell $(1) -e 'use Config; print $$Config{archname}')
# Optimally we should ask perl which C compiler was used but it doesn't
# result in a full path name.  Only "c" is being recorded
# inside perl builds while we actually need a full path to
# the compiler.
#PERL_CC =	$(shell $(PERL) -e 'use Config; print $$Config{cc}')

# PERL options which depend on C options should be placed here
PERL_OPTIMIZE =	$(shell $(PERL) -e 'use Config; print $$Config{optimize}')

PKG_MACROS +=   PERL_ARCH=$(PERL_ARCH)
PKG_MACROS +=   PERL_VERSION=$(PERL_VERSION)

#
# Upstream supports major PostgreSQL versions for 5 years after its initial
# release.  After that one last minor version is released and then the major
# version is considered EOL.
#
# We will start to obsolete PostgreSQL versions according the following table:
#
# +--------------------+----------------+
# | PostgreSQL version | Obsolete after |
# +--------------------+----------------+
# |         14         |   2026-11-12   |
# |         15         |   2027-11-11   |
# |         16         |   2028-11-09   |
# +--------------------+----------------+
#
# See https://www.postgresql.org/support/versioning/
#

# Config magic for Postgres/EnterpriseDB/...
# Default DB version should be the newest one we do have so we detect any
# incompatibilities as soon as possible.  Components could override this when
# they are not ready yet to compile with so new version.
PG_VERSION ?=   16
PG_IMPLEM ?=    postgres
PG_VERNUM =     $(subst .,,$(PG_VERSION))
# For dependencies, including REQUIRED_PACKAGES if needed
PG_BASEPKG =    database/$(PG_IMPLEM)-$(PG_VERNUM)
PG_CLIENT_PKG = $(PG_BASEPKG)/client
PG_DEVELOPER_PKG = $(PG_BASEPKG)/developer
PG_LIBRARY_PKG = $(PG_BASEPKG)/library
PG_SERVICE_PKG = service/$(PG_BASEPKG)

REQUIRED_PACKAGES_SUBST+= PG_CLIENT_PKG
REQUIRED_PACKAGES_SUBST+= PG_DEVELOPER_PKG
REQUIRED_PACKAGES_SUBST+= PG_LIBRARY_PKG
REQUIRED_PACKAGES_SUBST+= PG_SERVICE_PKG

PG_HOME =       $(USRDIR)/$(PG_IMPLEM)/$(PG_VERSION)
PG_BINDIR.32 =  $(PG_HOME)/bin/$(MACH32)
PG_BINDIR.64 =  $(PG_HOME)/bin
PG_BINDIR =     $(PG_BINDIR.$(BITS))
PG_INCDIR =     $(PG_HOME)/include
PG_MANDIR =     $(PG_HOME)/man
PG_SHAREDIR =   $(PG_HOME)/share
PG_DOCDIR =     $(PG_HOME)/doc
PG_LIBDIR.32 =  $(PG_HOME)/lib
PG_LIBDIR.64 =  $(PG_HOME)/lib/$(MACH64)
PG_LIBDIR =     $(PG_LIBDIR.$(BITS))
PG_CONFIG.32 =  $(PG_BINDIR.32)/pg_config
PG_CONFIG.64 =  $(PG_BINDIR.64)/pg_config
PG_CONFIG =     $(PG_CONFIG.$(BITS))
PATH.prepend +=	$(PG_BINDIR)

PKG_MACROS +=   PG_VERSION=$(PG_VERSION)
PKG_MACROS +=   PG_VERNUM=$(PG_VERNUM)
PKG_MACROS +=   PG_BASEPKG=$(PG_BASEPKG)

#
# Upstream maintains long-term MariaDB releases for at least 5 years and
# short-term MariaDB releases for at least one year.
#
# We will start to obsolete MariaDB versions according the following table:
#
# +-----------------+----------------+
# | MariaDB version | Obsolete after |
# +-----------------+----------------+
# |      10.6       |   2026-07      |
# +-----------------+----------------+
#
# See https://mariadb.org/about/#maintenance-policy
#

# Config magic for MySQL/MariaDB/Percona/...
# Default DB version should be the newest one we do have so we detect any
# incompatibilities as soon as possible.  Components could override this when
# they are not ready yet to compile with so new version.
# NOTE: At this time the gate does not provide a recipe for actual "mysql"
# The "/usr/mysql/*" trees are mediated to preferred MariaDB or Percona variant
MYSQL_VERSION ?=   10.6
MYSQL_IMPLEM ?=    mariadb
MYSQL_VERNUM =     $(subst .,,$(MYSQL_VERSION))
# For dependencies, including REQUIRED_PACKAGES if needed
MYSQL_BASEPKG =    database/$(MYSQL_IMPLEM)-$(MYSQL_VERNUM)
MYSQL_CLIENT_PKG = $(MYSQL_BASEPKG)/client
MYSQL_DEVELOPER_PKG = $(MYSQL_BASEPKG)/developer
MYSQL_LIBRARY_PKG = $(MYSQL_BASEPKG)/library

REQUIRED_PACKAGES_SUBST+= MYSQL_CLIENT_PKG
REQUIRED_PACKAGES_SUBST+= MYSQL_DEVELOPER_PKG
REQUIRED_PACKAGES_SUBST+= MYSQL_LIBRARY_PKG

MYSQL_HOME =       $(USRDIR)/$(MYSQL_IMPLEM)/$(MYSQL_VERSION)
MYSQL_BINDIR =		$(MYSQL_HOME)/bin
# The MYSQL_BINDIR.64 variable is set for compatibility with some components
# that still use $(MYSQL_BINDIR.$(BITS)) or $(MYSQL_BINDIR.64).  Once they are
# converted to plain $(MYSQL_BINDIR) we should remove the MYSQL_BINDIR.64 here.
MYSQL_BINDIR.64 =	$(MYSQL_BINDIR)
MYSQL_INCDIR =     $(MYSQL_HOME)/include
MYSQL_MANDIR =     $(MYSQL_HOME)/man
MYSQL_SHAREDIR =   $(MYSQL_HOME)/share
MYSQL_DOCDIR =     $(MYSQL_HOME)/doc
MYSQL_LIBDIR.32 =  $(MYSQL_HOME)/lib
MYSQL_LIBDIR.64 =  $(MYSQL_HOME)/lib/$(MACH64)
MYSQL_LIBDIR =     $(MYSQL_LIBDIR.$(BITS))
MYSQL_CONFIG.32 =  $(MYSQL_BINDIR.32)/mysql_config
MYSQL_CONFIG.64 =  $(MYSQL_BINDIR.64)/mysql_config
MYSQL_CONFIG =     $(MYSQL_CONFIG.$(BITS))
MYSQL_PKG_CONFIG_PATH =	$(MYSQL_LIBDIR)/pkgconfig
PATH.prepend +=		$(MYSQL_BINDIR)
PKG_CONFIG_PATH.prepend +=	$(MYSQL_PKG_CONFIG_PATH)

PKG_MACROS +=   MYSQL_VERSION=$(MYSQL_VERSION)
PKG_MACROS +=   MYSQL_VERNUM=$(MYSQL_VERNUM)
PKG_MACROS +=   MYSQL_BASEPKG=$(MYSQL_BASEPKG)

# Default libjpeg implementation layout
JPEG_DEFAULT =		8
JPEG_VERSION ?=		$(JPEG_DEFAULT)
JPEG_IMPLEM =		libjpeg$(JPEG_VERSION)-turbo
JPEG_HOME =		$(if $(filter $(JPEG_DEFAULT),$(JPEG_VERSION)),$(USRDIR),$(USRLIBDIR)/$(JPEG_IMPLEM))
JPEG_INCDIR =		$(if $(filter $(JPEG_DEFAULT),$(JPEG_VERSION)),$(USRINCDIR),$(USRINCDIR)/$(JPEG_IMPLEM))
JPEG_LIBDIR.32 =   $(JPEG_HOME)/lib
JPEG_LIBDIR.64 =   $(JPEG_HOME)/lib/$(MACH64)
JPEG_LIBDIR =      $(JPEG_LIBDIR.$(BITS))
JPEG_CPPFLAGS =    -I$(JPEG_INCDIR)
JPEG_CFLAGS.32 =   -Wl,-L$(JPEG_LIBDIR.32) -Wl,-R$(JPEG_LIBDIR.32)
JPEG_CFLAGS.64 =   -Wl,-L$(JPEG_LIBDIR.64) -Wl,-R$(JPEG_LIBDIR.64)
JPEG_CFLAGS =      $(JPEG_CFLAGS.$(BITS))
JPEG_CXXFLAGS.32 = -Wl,-L$(JPEG_LIBDIR.32) -Wl,-R$(JPEG_LIBDIR.32)
JPEG_CXXFLAGS.64 = -Wl,-L$(JPEG_LIBDIR.64) -Wl,-R$(JPEG_LIBDIR.64)
JPEG_CXXFLAGS =    $(JPEG_CXXFLAGS.$(BITS))
JPEG_LDFLAGS.32 =  -L$(JPEG_LIBDIR.32) -R$(JPEG_LIBDIR.32)
JPEG_LDFLAGS.64 =  -L$(JPEG_LIBDIR.64) -R$(JPEG_LIBDIR.64)
JPEG_LDFLAGS =     $(JPEG_LDFLAGS.$(BITS))

PKG_CONFIG_PATH.prepend +=	$(if $(filter $(JPEG_DEFAULT),$(JPEG_VERSION)),,$(JPEG_LIBDIR)/pkgconfig)

JPEG_IMPLEM_PKG = image/library/$(JPEG_IMPLEM)
REQUIRED_PACKAGES_SUBST += JPEG_IMPLEM_PKG

# This is the default BUILD version of tcl
# Not necessarily the system's default version, i.e. /usr/bin/tclsh
TCL_VERSION =  8.6
TCLSH.8.6.i386.32 =	/usr/bin/i86/tclsh8.6
TCLSH.8.6.i386.64 =	/usr/bin/amd64/tclsh8.6
TCLSH.8.6.sparc.32 =	/usr/bin/sparcv7/tclsh8.6
TCLSH.8.6.sparc.64 =	/usr/bin/sparcv9/tclsh8.6
TCLSH =		$(TCLSH.$(TCL_VERSION).$(MACH).$(BITS))

# ICU library
ICU_VERSION =			77
ICU_LIBRARY_PKG =		library/icu-$(ICU_VERSION)
REQUIRED_PACKAGES_SUBST +=	ICU_LIBRARY_PKG

# GNU readline
READLINE_VERSION =		8
READLINE_PKG =			library/readline-$(READLINE_VERSION)
REQUIRED_PACKAGES_SUBST +=	READLINE_PKG


CCSMAKE =	/usr/ccs/bin/make
GMAKE =		/usr/gnu/bin/make
GPATCH =	/usr/gnu/bin/patch
PATCH_LEVEL =	1
GPATCH_BACKUP =	--backup --version-control=numbered
GPATCH_FLAGS =	-p$(PATCH_LEVEL) $(GPATCH_BACKUP)
GSED =		/usr/gnu/bin/sed
GDIFF =		/usr/gnu/bin/diff
GSORT =		/usr/gnu/bin/sort
GUNZIP =	/usr/bin/gunzip

SORT =		LC_ALL=C /usr/bin/sort

PKGREPO =	/usr/bin/pkgrepo
PKGSEND =	/usr/bin/pkgsend
ifeq   ($(strip $(PKGLINT_COMPONENT)),)
PKGLINT =	/usr/bin/python /usr/bin/pkglint
else
PKGLINT =	${WS_TOOLS}/pkglint
endif

ACLOCAL =	/usr/bin/aclocal-1.16
AUTOMAKE =	/usr/bin/automake-1.16
AUTORECONF = 	/usr/bin/autoreconf

KSH93 =         /usr/bin/ksh93
TOUCH =		/usr/bin/touch
MKDIR =		/bin/mkdir -p
RM =		/bin/rm -f
CP =		/bin/cp -f
MV =		/bin/mv -f
LN =		/bin/ln
CAT =		/bin/cat
SYMLINK =	/bin/ln -s
ENV =		/usr/bin/env -i
FIND =		/usr/bin/find
INSTALL =	/usr/bin/ginstall
GNU_GREP =	/usr/gnu/bin/grep
CHMOD =		/usr/bin/chmod
NAWK =		/usr/bin/nawk
TEE =		/usr/bin/tee
GAS =		/usr/gnu/bin/as
GTAR =		/usr/gnu/bin/tar
STRIP =	/usr/bin/strip
IPS2TGZ = 	$(WS_TOOLS)/ips2tgz
JQ =		/usr/bin/jq
DOS2UNIX =	/usr/bin/dos2unix
TAC =		/usr/bin/tac
QUILT =		/usr/bin/quilt
CTFCONVERT =	/opt/onbld/bin/$(MACH)/ctfconvert
ELFEDIT =	/usr/bin/elfedit

INS.dir=        $(INSTALL) -d $@
INS.file=       $(INSTALL) -m 444 $< $(@D)

# OpenSSL macros
OPENSSL_DEFAULT = 3
ifeq ($(strip $(USE_OPENSSL11)),yes)
OPENSSL_VERSION = 1.1
else
ifeq ($(strip $(USE_OPENSSL10)),yes)
OPENSSL_VERSION = 1.0
else
OPENSSL_VERSION ?= $(OPENSSL_DEFAULT)
endif
endif
PATH.prepend+=$(OPENSSL_BINDIR)
OPENSSL_PREFIX= $(USRDIR)/openssl/$(OPENSSL_VERSION)
OPENSSL_BINDIR.64= $(OPENSSL_PREFIX)/bin
OPENSSL_BINDIR.32= $(OPENSSL_PREFIX)/bin/$(MACH32)
OPENSSL_BINDIR= $(OPENSSL_BINDIR.$(BITS))
OPENSSL_LIBDIR.64= $(OPENSSL_PREFIX)/lib/$(MACH64)
OPENSSL_LIBDIR.32= $(OPENSSL_PREFIX)/lib
OPENSSL_LIBDIR= $(OPENSSL_LIBDIR.$(BITS))
OPENSSL_PKG_CONFIG_PATH.32= $(OPENSSL_PREFIX)/lib/pkgconfig
OPENSSL_PKG_CONFIG_PATH.64= $(OPENSSL_PREFIX)/lib/$(MACH64)/pkgconfig
OPENSSL_PKG_CONFIG_PATH= $(OPENSSL_PKG_CONFIG_PATH.$(BITS))
OPENSSL_INCDIR=$(OPENSSL_PREFIX)/include
OPENSSL_ETCDIR=$(ETCDIR)/openssl/$(OPENSSL_VERSION)

PKG_CONFIG_PATH.prepend +=	$(OPENSSL_PKG_CONFIG_PATH)

# The OpenSSL 1.0 package is without the version suffix so it needs special handling
OPENSSL_PKG =			library/security/openssl$(subst -10,,-$(subst .,,$(OPENSSL_VERSION)))
REQUIRED_PACKAGES_SUBST +=	OPENSSL_PKG

#
# Rust macros
#

# Rust target triplet
RUST_TRIPLET = $(RUST_CPU)-$(RUST_VENDOR)-$(RUST_OS)
RUST_CPU = x86_64
RUST_VENDOR = unknown
RUST_OS = illumos

# This is the linker we would like to use with cargo
CARGO_TARGET_LINKER = $(CC)


# Pkg-config paths
PKG_CONFIG_PATH.32 = /usr/lib/pkgconfig
PKG_CONFIG_PATH.64 = /usr/lib/$(MACH64)/pkgconfig
PKG_CONFIG_PATH = $(subst $(space),:,$(strip $(PKG_CONFIG_PATH.prepend))):$(PKG_CONFIG_PATH.$(BITS)):$(PKG_CONFIG_PATH.32)

# Set default path for environment modules
MODULE_VERSION =	3.2.10
MODULE_PATH =		/usr/share/Modules/modulefiles
MODULE_VERSIONS_PATH =	/usr/share/Modules/versions

# Path to bash completions
BASH_COMPLETIONS_PATH =	/usr/share/bash-completion/completions

#
# C preprocessor flag sets to ease feature selection.  Add the required
# feature to your Makefile with CPPFLAGS += $(FEATURE_MACRO) and add to
# the component build with CONFIGURE_OPTIONS += CPPFLAGS="$(CPPFLAGS)" or
# similiar.
#

# Enables visibility of some c99 math functions that aren't visible by default.
# What other side-effects are there?
CPP_C99_EXTENDED_MATH =	-D_STDC_99

# Enables large file support for components that have no other means of doing
# so.  Use CPP_LARGEFILES and not the .32/.64 variety directly
CPP_LARGEFILES.32 :=	$(shell $(GETCONF) LFS_CFLAGS)
CPP_LARGEFILES.64 :=	$(shell $(GETCONF) LFS64_CFLAGS)
CPP_LARGEFILES =		$(CPP_LARGEFILES.$(BITS))

# Enables some #pragma redefine_extname to POSIX-compliant Standard C Library
# functions. Also avoids the component's #define _POSIX_C_SOURCE to some value
# we currently do not support.
CPP_POSIX =	-D_POSIX_C_SOURCE=200112L -D_POSIX_PTHREAD_SEMANTICS

# XPG8 mode.  This option enables XPG8 conformance, plus extensions.
CPP_XPG8MODE=	-D_XOPEN_SOURCE=800 -D__EXTENSIONS__=1 -D_XPG8

# XPG7 mode.  This option enables XPG7 conformance, plus extensions.
CPP_XPG7MODE=	-D_XOPEN_SOURCE=700 -D__EXTENSIONS__=1 -D_XPG7

# XPG6 mode.  This option enables XPG6 conformance, plus extensions.
# Amongst other things, this option will cause system calls like
# popen (3C) and system (3C) to invoke the standards-conforming
# shell, /usr/xpg4/bin/sh, instead of /usr/bin/sh.  Add CPP_XPG6MODE to
# CFLAGS instead of using this directly
CPP_XPG6MODE=	-D_XOPEN_SOURCE=600 -D__EXTENSIONS__=1 -D_XPG6

# XPG5 mode. These options are specific for C++, where _XPG6,
# _XOPEN_SOURCE=600 and C99 are illegal. -D__EXTENSIONS__=1 is legal in C++.
CPP_XPG5MODE=   -D_XOPEN_SOURCE=500 -D__EXTENSIONS__=1 -D_XPG5

# Generate 32/64 bit objects
CC_BITS =	-m$(BITS)

# Turn on C99 for gcc
gcc_C99_ENABLE =	-std=c99

# Turn on C23 for gcc
#
# Please note that gcc up to version 14 does not fully support C23 and so
# __STDC_VERSION__ does not expand to 202311L there, but to 202000L instead.
# This is not sufficient for turning on C23 in our headers and so we need to
# define _STDC_C23 as well.  See /usr/include/sys/feature_tests.h for details.
#
# Although the -std=c2x option is deprecated (since gcc 14) and -std=c23 should
# be used instead, it is not available for gcc 13 and older and so we opted to
# use -std=c2x for compatibility.
gcc_C23_ENABLE =	-std=c2x -D_STDC_C23

# Control register usage for generated code.  SPARC ABI requires system
# libraries not to use application registers.
gcc_XREGS.sparc =	-mno-app-regs
gcc_XREGS.i386 =
gcc_XREGS =		$(gcc_XREGS.$(MACH))

# See CPP_XPG8MODE comment above.
XPG8MODE =		$(CPP_XPG8MODE)

# See CPP_XPG7MODE comment above.
XPG7MODE =		$(CPP_XPG7MODE)

# See CPP_XPG6MODE comment above.
XPG6MODE =		$(CPP_XPG6MODE)

# See CPP_XPG5MODE comment above. You can only use this in C++, not in C99.
XPG5MODE =		$(CPP_XPG5MODE)

#
# GNU C compiler flag sets to ease feature selection.  Add the required
# feature to your Makefile with CFLAGS += $(FEATURE_MACRO) and add to the
# component build with CONFIGURE_OPTIONS += CFLAGS="$(CFLAGS)" or similiar.
#

# Control the GCC optimization level.
gcc_OPT.sparc.32 =	-O3 -mcpu=ultrasparc -mvis -mfsmuld
gcc_OPT.sparc.64 =	-O3 -mcpu=ultrasparc -mvis -mfsmuld
gcc_OPT.i386.32 =	-O3
gcc_OPT.i386.64 =	-O3
gcc_OPT =		$(gcc_OPT.$(MACH).$(BITS))

# GCC PIC code generation.  Use CC_PIC instead to select PIC code generation.
gcc_PIC =	-fPIC -DPIC

# Generic macro for PIC code generation.  Use this macro instead of the
# compiler specific variant.
CC_PIC =	$($(COMPILER)_PIC)


# Default GNU C compiler flags.  Add the required feature to your Makefile
# with CFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += CFLAGS="$(CFLAGS)" or similiar.  In most cases, it
# should not be necessary to add CFLAGS to any environment other than the
# configure environment.
CFLAGS.gcc +=	$(gcc_OPT)
CFLAGS.gcc +=	$(gcc_XREGS)

# Default GNU C++ compiler flags.  Add the required feature to your Makefile
# with CXXFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += CXXFLAGS="$(CXXFLAGS)" or similiar.  In most cases, it
# should not be necessary to add CXXFLAGS to any environment other than the
# configure environment.
CXXFLAGS.gcc +=	$(gcc_OPT)
CXXFLAGS.gcc +=	$(gcc_XREGS)

# Default GNU FORTRAN compiler flags.  Add the required feature to your Makefile
# with FCFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += FCFLAGS="$(FCFLAGS)" or similiar.  In most cases, it
# should not be necessary to add FCFLAGS to any environment other than the
# configure environment.
FCFLAGS.gcc +=	$(gcc_OPT)
FCFLAGS.gcc +=	$(gcc_XREGS)

# Build 32 or 64 bit objects.
CFLAGS +=	$(CC_BITS)

# Add compiler specific 'default' features
CFLAGS +=	$(CFLAGS.$(COMPILER))

# Per-compiler CFLAGS to use when building for CTF.  Currently only defined
# for gcc; could be made to work with other compilers.

# -gdwarf-4 is the newest DWARF revision understood by illumos libctf
#
# -gstrict-dwarf prevents the compiler from including newer DWARF features
CTF_CFLAGS.gcc = -g -gdwarf-4 -gstrict-dwarf
# -msave-args makes it possible for debugging tools (specifically pstack and
# mdb) to retrieve function arguments, and is required for the python pstack
# hooks.
CTF_CFLAGS.gcc += -msave-args
# By default, GCC may put parts of functions in different named sub-sections
# of .text based on their presumed or measured calling frequency.  This is not
# currently handled by libctf and other illumos tools which assume that a
# function's text lies in a single contiguous range of virtual addresses.
# Disable this optimization if building with CTF.
CTF_CFLAGS.gcc += -fno-reorder-functions -fno-reorder-blocks-and-partition

# Enable CTF if desired
ifeq ($(strip $(USE_CTF)),yes)
CFLAGS += $(if $(CTF_CFLAGS.$(COMPILER)), \
	$(CTF_CFLAGS.$(COMPILER)), \
	$(error Error: CTF_CFLAGS.$(COMPILER) must be defined to use CTF with $(COMPILER)))
endif

# Build 32 or 64 bit objects in C++ as well.
CXXFLAGS +=	$(CC_BITS)

# Add compiler specific 'default' features
CXXFLAGS +=	$(CXXFLAGS.$(COMPILER))

# Build 32 or 64 bit objects in FORTRAN as well.
F77FLAGS +=	$(CC_BITS)
FCFLAGS +=	$(CC_BITS)

# Add compiler specific 'default' features
F77FLAGS +=	$(FCFLAGS.$(COMPILER))
FCFLAGS +=	$(FCFLAGS.$(COMPILER))

#
# Solaris linker flag sets to ease feature selection.  Add the required
# feature to your Makefile with LDFLAGS += $(FEATURE_MACRO) and add to the
# component build with CONFIGURE_OPTIONS += LDFLAGS="$(LDFLAGS)" or similiar.
#

# set the bittedness that we want to link
ccs.ld.64 = -64
gcc.ld.32 = -m32
gcc.ld.64 = -m64
LD_BITS =      $($(LINKER).ld.$(BITS))
LDFLAGS =      $(LD_BITS)

# Reduce the symbol table size, effectively conflicting with -g.  We should
# get linker guidance here.
LD_Z_REDLOCSYM =	-z redlocsym

# Cause the linker to rescan archive libraries and resolve remaining unresolved
# symbols recursively until all symbols are resolved.  Components should be
# linking in the libraries they need, in the required order.  This should
# only be required if the component's native build is horribly broken.
LD_Z_RESCAN_NOW =	-z rescan-now

LD_Z_TEXT =		-z direct

# make sure that -lc is always present when building shared objects.
LD_DEF_LIBS +=		-lc

# make sure all symbols are defined.
LD_Z_DEFS =		-z defs

# eliminate unreferenced dynamic dependencies
LD_Z_IGNORE =		-z ignore

# use direct binding
LD_B_DIRECT =		-Bdirect

# use generic macro names for enabling/disabling ASLR
ASLR_ENABLE = 		-z aslr=enable
ASLR_DISABLE = 		-z aslr=disable
ASLR_MODE = 		$(ASLR_DISABLE)

# by default, turn off Address Space Layout Randomization for ELF executables;
# to explicitly enable ASLR, set ASLR_MODE = $(ASLR_ENABLE)
# in that component's Makefile
LD_Z_ASLR =		$(ASLR_MODE)

# Define SSP library link flag for 32-bit objects
LD_SSP.32 = -lssp_ns
LD_SSP.64 =
LD_SSP = $(LD_SSP.$(BITS))

#
# More Solaris linker flags that we want to be sure that everyone gets.  This
# is automatically added to the calling environment during the 'build' and
# 'install' phases of the component build.  Each individual feature can be
# turned off by adding FEATURE_MACRO= to the component Makefile.
#

# Create a non-executable stack when linking.
LD_MAP_NOEXSTK.i386 =	-M /usr/lib/ld/map.noexstk
LD_MAP_NOEXSTK.sparc =	-M /usr/lib/ld/map.noexstk

# Create a non-executable bss segment when linking.
LD_MAP_NOEXBSS =	-M /usr/lib/ld/map.noexbss

# Create a non-executable data segment when linking.  Due to PLT needs, the
# data segment must be executable on sparc, but the bss does not.
# see mapfile comments for more information
LD_MAP_NOEXDATA.i386 =	-M /usr/lib/ld/map.noexdata
LD_MAP_NOEXDATA.sparc =	$(LD_MAP_NOEXBSS)

# Page alignment
LD_MAP_PAGEALIGN =	-M /usr/lib/ld/map.pagealign

# Linker options to add when only building libraries
LD_OPTIONS_SO +=	$(LD_Z_TEXT) $(LD_Z_DEFS) $(LD_DEF_LIBS)

# Default linker options that everyone should get.  Do not add additional
# libraries to this macro, as it will apply to everything linked during the
# component build.
LD_OPTIONS +=	$(LD_MAP_NOEXSTK.$(MACH)) $(LD_MAP_NOEXDATA.$(MACH)) \
		$(LD_MAP_PAGEALIGN) $(LD_B_DIRECT) $(LD_Z_IGNORE)

# only used on executables
LD_EXEC_OPTIONS = $(LD_Z_ASLR)

# Environment variables and arguments passed into the build and install
# environment(s).  These are the initial settings.
COMPONENT_BUILD_ENV= \
    LD_OPTIONS="$(LD_OPTIONS)" \
    LD_EXEC_OPTIONS="$(LD_EXEC_OPTIONS)"
COMPONENT_INSTALL_ENV= \
    LD_OPTIONS="$(LD_OPTIONS)" \
    LD_EXEC_OPTIONS="$(LD_EXEC_OPTIONS)"

# PATH should be always set
COMPONENT_BUILD_ENV += PATH="$(PATH)"
COMPONENT_INSTALL_ENV += PATH="$(PATH)"
COMPONENT_TEST_ENV += PATH="$(PATH)"

# Rewrite absolute source-code paths into relative for ccache, so that any
# workspace with a shared CCACHE_DIR can benefit when compiling a component
ifneq ($(strip $(CCACHE)),)
export CCACHE_BASEDIR = $(BUILD_DIR_$(BITS))
COMPONENT_BUILD_ENV += CCACHE="$(CCACHE)"
COMPONENT_INSTALL_ENV += CCACHE="$(CCACHE)"
COMPONENT_TEST_ENV += CCACHE="$(CCACHE)"
COMPONENT_BUILD_ENV += CC_gcc_32="$(CC_gcc_32)"
COMPONENT_BUILD_ENV += CC_gcc_64="$(CC_gcc_64)"
COMPONENT_BUILD_ENV += CXX_gcc_32="$(CXX_gcc_32)"
COMPONENT_BUILD_ENV += CXX_gcc_64="$(CXX_gcc_64)"
COMPONENT_INSTALL_ENV += CC_gcc_32="$(CC_gcc_32)"
COMPONENT_INSTALL_ENV += CC_gcc_64="$(CC_gcc_64)"
COMPONENT_INSTALL_ENV += CXX_gcc_32="$(CXX_gcc_32)"
COMPONENT_INSTALL_ENV += CXX_gcc_64="$(CXX_gcc_64)"
COMPONENT_TEST_ENV += CC_gcc_32="$(CC_gcc_32)"
COMPONENT_TEST_ENV += CC_gcc_64="$(CC_gcc_64)"
COMPONENT_TEST_ENV += CXX_gcc_32="$(CXX_gcc_32)"
COMPONENT_TEST_ENV += CXX_gcc_64="$(CXX_gcc_64)"
COMPONENT_BUILD_ENV.$(BITS) += CCACHE_BASEDIR="$(BUILD_DIR_$(BITS))"
COMPONENT_INSTALL_ENV.$(BITS) += CCACHE_BASEDIR="$(BUILD_DIR_$(BITS))"
COMPONENT_TEST_ENV.$(BITS) += CCACHE_BASEDIR="$(BUILD_DIR_$(BITS))"

ifneq ($(strip $(CCACHE_DIR)),)
COMPONENT_BUILD_ENV += CCACHE_DIR="$(CCACHE_DIR)"
COMPONENT_INSTALL_ENV += CCACHE_DIR="$(CCACHE_DIR)"
COMPONENT_TEST_ENV += CCACHE_DIR="$(CCACHE_DIR)"
endif

ifneq ($(strip $(CCACHE_LOGFILE)),)
COMPONENT_BUILD_ENV += CCACHE_LOGFILE="$(CCACHE_LOGFILE)"
COMPONENT_INSTALL_ENV += CCACHE_LOGFILE="$(CCACHE_LOGFILE)"
COMPONENT_TEST_ENV += CCACHE_LOGFILE="$(CCACHE_LOGFILE)"
endif

endif

# Add any bit-specific settings
COMPONENT_BUILD_ENV += $(COMPONENT_BUILD_ENV.$(BITS))
COMPONENT_BUILD_ARGS += $(COMPONENT_BUILD_ARGS.$(BITS))
COMPONENT_INSTALL_ENV += $(COMPONENT_INSTALL_ENV.$(BITS))
COMPONENT_INSTALL_ARGS += $(COMPONENT_INSTALL_ARGS.$(BITS))

# declare these phony so that we avoid filesystem conflicts.
.PHONY:	prep build install publish test clean clobber

# If there are no tests to execute
NO_TESTS =	test-nothing
test-nothing:
	@echo "There are no tests available at this time."

# default behaviour for 'component-hook' target is to echo the component
# name and version information, but more complex behaviour can be implemented
# via command line setting of the COMPONENT_HOOK macro.
COMPONENT_HOOK ?=	echo $(COMPONENT_NAME) $(COMPONENT_VERSION)

component-hook:
	@$(COMPONENT_HOOK)

# We need shell/ksh93 to be able to run scripts in the tools directory
USERLAND_REQUIRED_PACKAGES += shell/ksh93

#
# Packages with tools that are required to build Userland components
#
USERLAND_REQUIRED_PACKAGES += metapackages/build-essential

# Define substitution rules for some packages.
# Such package names may change and would be better defined with a macro to
# avoid mass modification of the Makefiles.

# Runtime package names are changed at compiler version major bumps.
REQUIRED_PACKAGES_SUBST+= GCC_RUNTIME_PKG
REQUIRED_PACKAGES_SUBST+= GXX_RUNTIME_PKG
REQUIRED_PACKAGES_SUBST+= GCCGO_RUNTIME_PKG
REQUIRED_PACKAGES_SUBST+= GFORTRAN_RUNTIME_PKG
REQUIRED_PACKAGES_SUBST+= GOBJC_RUNTIME_PKG

# Generate requirements on all built python version variants for given packages
USERLAND_REQUIRED_PACKAGES += $(foreach ver,$(PYTHON_VERSIONS),$(USERLAND_REQUIRED_PACKAGES.python:%=%-$(subst .,,$(ver))))
REQUIRED_PACKAGES += $(foreach ver,$(PYTHON_VERSIONS),$(PYTHON_REQUIRED_PACKAGES:%=%-$(subst .,,$(ver))))
TEST_REQUIRED_PACKAGES += $(foreach ver,$(PYTHON_VERSIONS),$(TEST_REQUIRED_PACKAGES.python:%=%-$(subst .,,$(ver))))

# Generate requirements on all built perl version variants for given packages
USERLAND_REQUIRED_PACKAGES += $(foreach ver,$(PERL_VERSIONS),$(USERLAND_REQUIRED_PACKAGES.perl:%=%-$(subst .,,$(ver))))
REQUIRED_PACKAGES += $(foreach ver,$(PERL_VERSIONS),$(PERL_REQUIRED_PACKAGES:%=%-$(subst .,,$(ver))))
TEST_REQUIRED_PACKAGES += $(foreach ver,$(PERL_VERSIONS),$(TEST_REQUIRED_PACKAGES.perl:%=%-$(subst .,,$(ver))))

# Generate conflicting packages for all built python version variants for given package
TEST_CONFLICTING_PACKAGES += $(foreach ver,$(PYTHON_VERSIONS),$(TEST_CONFLICTING_PACKAGES.python:%=%-$(subst .,,$(ver))))

# This is useful for symlinks creation in the post-install step
define create-symlinks
	for f in $(1:%=$(PROTO_DIR)/%) ; do \
		[ -e "$$f" ] || continue ; \
		t=$(PROTO_DIR)/$(2) ; \
		while true ; do \
			while [ "$${f#/}" != "$$f" ] ; do f=$${f#/} ; done ; \
			while [ "$${t#/}" != "$$t" ] ; do t=$${t#/} ; done ; \
			[ "$${f%%/*}" == "$${t%%/*}" ] || break ; \
			f=$${f#$${f%%/*}} ; \
			t=$${t#$${t%%/*}} ; \
		done ; \
		[ "$$t" ] && t=$$t/ ; \
		f=$$(echo $$t | $(GSED) -e 's|[^/]\{1,\}|..|g')$$f ; \
		$(MKDIR) $(PROTO_DIR)/$(2) ; \
		$(SYMLINK) $$f $(PROTO_DIR)/$(2)/$$(basename $$f) ; \
	done
endef

# Targets for some tools rarely used by the build framework.  We do not add
# these tools to USERLAND_REQUIRED_PACKAGES to do not pollute it.
$(QUILT):
	@echo
	@echo "$(QUILT) is missing"
	@echo "Please install developer/quilt package"
	@echo
	@exit 1

include $(WS_MAKE_RULES)/environment.mk
include $(WS_MAKE_RULES)/depend.mk
include $(WS_MAKE_RULES)/component.mk 

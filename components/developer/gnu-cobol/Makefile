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
# Copyright (c) 2014, David Hoeppner. All rights reserved.
#
BUILD_STYLE=configure
BUILD_BITS=64
include ../../../make-rules/shared-macros.mk

COMPONENT_NAME=         gnu-cobol
COMPONENT_VERSION=      1.1
COMPONENT_REVISION=     1
COMPONENT_FMRI=         developer/gnu-cobol
COMPONENT_SUMMARY=      COBOL to C compiler
COMPONENT_CLASSIFICATION=Development/Other Languages
COMPONENT_PROJECT_URL=  http://sourceforge.net/projects/open-cobol/
COMPONENT_SRC=          $(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=      $(COMPONENT_SRC).tar.gz
COMPONENT_ARCHIVE_HASH= \
	sha256:bd319c0d001e85835c8501ad74c9de0052fe82b8a38b4530f41b49b2af028b9d
COMPONENT_ARCHIVE_URL=  http://ftp.gnu.org/gnu/gnucobol/$(COMPONENT_ARCHIVE)
COMPONENT_LICENSE=      GPLv2, GFDLv1.2, LGPLv2.1

# When CONFIGURE_FIX_LIBTOOL_RPATH is integrated, we can remove local fix and enable it
CONFIGURE_FIX_LIBTOOL_RPATH = no

include $(WS_MAKE_RULES)/common.mk

COMPONENT_PREP_ACTION = (cd $(@D) && libtoolize -f && autoreconf -fi)

CONFGIURE_OPTIONS +=	--with-cflags="$(CFLAGS)"
CONFIGURE_OPTIONS +=	--infodir=$(CONFIGURE_INFODIR)

CONFIGURE_ENV.64 += LT_SYS_LIBRARY_PATH="/lib/$(MACH64):/usr/lib/$(MACH64)"

# Auto-generated dependencies
REQUIRED_PACKAGES += database/berkeleydb-5
REQUIRED_PACKAGES += library/gmp
REQUIRED_PACKAGES += library/ncurses
REQUIRED_PACKAGES += shell/ksh93
REQUIRED_PACKAGES += system/library
REQUIRED_PACKAGES += system/library/math

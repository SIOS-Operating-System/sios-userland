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
# Copyright 2014 Alexander Pyhalov.  All rights reserved.
# Copyright 2018 Michal Nowak
# Copyright 2023 Andreas Wacknitz
#

BUILD_BITS= 64
BUILD_STYLE= meson
USE_DEFAULT_TEST_TRANSFORMS= yes
include ../../../make-rules/shared-macros.mk

COMPONENT_NAME=		cairomm
COMPONENT_VERSION=	1.14.5
COMPONENT_REVISION=	2
COMPONENT_SUMMARY=	cairomm - C++ Wrapper for the cairo Library
COMPONENT_SRC=		$(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=	$(COMPONENT_SRC).tar.xz
COMPONENT_ARCHIVE_HASH= sha256:70136203540c884e89ce1c9edfb6369b9953937f6cd596d97c78c9758a5d48db
COMPONENT_ARCHIVE_URL=	https://cairographics.org/releases/$(COMPONENT_ARCHIVE)
COMPONENT_PROJECT_URL=	https://cairographics.org/cairomm/
COMPONENT_FMRI=			library/desktop/c++/cairomm
COMPONENT_CLASSIFICATION=	Desktop (GNOME)/Libraries
COMPONENT_LICENSE=		LGPLv2
COMPONENT_LICENSE_FILE=	COPYING

include $(WS_MAKE_RULES)/common.mk

PATH= $(PATH.gnu)

CXXFLAGS += -std=c++17

CONFIGURE_OPTIONS += --sysconfdir=/etc
CONFIGURE_OPTIONS += -Dboost-shared=true

# Build dependency
REQUIRED_PACKAGES += developer/build/pkg-config
REQUIRED_PACKAGES += developer/documentation-tool/doxygen
REQUIRED_PACKAGES += developer/macro/gnu-m4
REQUIRED_PACKAGES += image/graphviz
REQUIRED_PACKAGES += library/desktop/c++/mm-common
REQUIRED_PACKAGES += library/libxslt
REQUIRED_PACKAGES += system/library/boost
REQUIRED_PACKAGES += system/library/fontconfig

# Auto-generated dependencies
REQUIRED_PACKAGES += $(GCC_RUNTIME_PKG)
REQUIRED_PACKAGES += $(GXX_RUNTIME_PKG)
REQUIRED_PACKAGES += library/c++/sigcpp
REQUIRED_PACKAGES += library/desktop/cairo
REQUIRED_PACKAGES += system/library

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
#   $WS_TOOLS/perl-integrate-module PAR::Dist
#

BUILD_STYLE = makemaker

include ../../../make-rules/shared-macros.mk

COMPONENT_PERL_MODULE =		PAR::Dist
HUMAN_VERSION =			0.53
COMPONENT_SUMMARY =		PAR::Dist - Create and manipulate PAR distributions
COMPONENT_CPAN_AUTHOR =		RSCHUPP
COMPONENT_ARCHIVE_HASH =	\
	sha256:04cbc81e786968f9a4109ad6c2f9b81e879ac0c6b6080a9d217443b61dfd2498
COMPONENT_LICENSE =		Artistic-1.0 OR GPL-1.0-or-later
COMPONENT_LICENSE_FILE =	LICENSE

include $(WS_MAKE_RULES)/common.mk

# Optional test dependencies missing from metadata
TEST_REQUIRED_PACKAGES.perl += library/perl-5/archive-zip
TEST_REQUIRED_PACKAGES.perl += library/perl-5/yaml-libyaml

# Auto-generated dependencies
PERL_REQUIRED_PACKAGES += runtime/perl

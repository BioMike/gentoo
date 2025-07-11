# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=SALVA
DIST_VERSION=0.54
DIST_EXAMPLES=( "examples/*" )
inherit perl-module

DESCRIPTION="Manipulate 64 bits integers in Perl"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~mips ~ppc ppc64 ~riscv ~s390 sparc x86"

RDEPEND=""
BDEPEND="${RDEPEND}
	test? (
		>=virtual/perl-Test-Simple-0.960.0
	)
"
PERL_RM_FILES=(
	"t/author-eol.t" "t/author-no-tabs.t" "t/author-pod-spell.t"
	"t/author-pod-syntax.t" "t/release-cpan-changes.t" "t/release-pod-coverage.t"
	"t/release-portability.t" "t/release-synopsis.t"
)

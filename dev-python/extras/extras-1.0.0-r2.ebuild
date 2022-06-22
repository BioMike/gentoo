# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} pypy3 )

inherit distutils-r1

DESCRIPTION="Useful extra bits for Python that should be in the standard library"
HOMEPAGE="
	https://github.com/testing-cabal/extras/
	https://pypi.org/project/extras/
"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc ~x86 ~x64-macos"

BDEPEND="
	test? (
		dev-python/testtools[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests unittest

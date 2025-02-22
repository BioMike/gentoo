# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

inherit autotools

DESCRIPTION="Brings up/down ethernet ports automatically with cable detection"
HOMEPAGE="http://0pointer.de/lennart/projects/ifplugd/"
SRC_URI="http://0pointer.de/lennart/projects/ifplugd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~hppa ppc x86"
IUSE="doc selinux"

DEPEND=">=dev-libs/libdaemon-0.5"
RDEPEND="
	${DEPEND}
	>=sys-apps/baselayout-1.12
	selinux? ( sec-policy/selinux-ifplugd )
"
BDEPEND="
	virtual/pkgconfig
	doc? ( www-client/lynx )
"

PATCHES=(
	"${FILESDIR}/${P}-nlapi.diff"
	"${FILESDIR}/${P}-interface.patch"
	"${FILESDIR}/${P}-strictalias.patch"
	"${FILESDIR}/${P}-noip.patch"
	"${FILESDIR}/${P}-musl.patch"
	"${FILESDIR}/${P}-gcc10-compatibility.patch"
	"${FILESDIR}/${P}-fix-if.h-include.patch"
)

DOCS=( doc/README doc/SUPPORTED_DRIVERS )
HTML_DOCS=( doc/README.html doc/style.css )

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	econf \
		$(use_enable doc lynx) \
		--with-initdir=/etc/init.d \
		--disable-xmltoman \
		--disable-subversion
}

src_install() {
	default

	# Remove init.d configuration as we no longer use it
	rm -rf "${ED}/etc/ifplugd" "${ED}/etc/init.d/${PN}" || die

	exeinto "/etc/${PN}"
	newexe "${FILESDIR}/${PN}.action" "${PN}.action"
}

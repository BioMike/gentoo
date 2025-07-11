# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic toolchain-funcs

MY_PN=${PN/-gpl}
MY_P="${MY_PN}-${PV/_}"
PVM=$(ver_cut 1-2)
PVM_S=$(ver_rs 1-2 "")

# Use https://gitweb.gentoo.org/proj/codec/ghostscript-gpl-patches.git/ for patches
# See 'index' branch for README
MY_PATCHSET="ghostscript-gpl-10.04.0-patches.tar.xz"

DESCRIPTION="Interpreter for the PostScript language and PDF"
HOMEPAGE="https://ghostscript.com/ https://git.ghostscript.com/?p=ghostpdl.git;a=summary"
SRC_URI="https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${PVM_S}/${MY_P}.tar.xz"
if [[ -n "${MY_PATCHSET}" ]] ; then
	SRC_URI+=" https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${MY_PATCHSET}"
fi
S="${WORKDIR}/${MY_P}"

LICENSE="AGPL-3 CPL-1.0"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="cups cpu_flags_arm_neon dbus gtk l10n_de static-libs unicode X"

LANGS="ja ko zh-CN zh-TW"
for X in ${LANGS} ; do
	IUSE="${IUSE} l10n_${X}"
done

DEPEND="
	app-text/libpaper:=
	media-libs/fontconfig
	>=media-libs/freetype-2.4.9:2=
	>=media-libs/jbig2dec-0.19:=
	>=media-libs/lcms-2.6:2
	>=media-libs/libpng-1.6.2:=
	media-libs/libjpeg-turbo:=
	>=media-libs/openjpeg-2.1.0:2=
	>=media-libs/tiff-4.0.1:=
	>=sys-libs/zlib-1.2.7
	cups? ( >=net-print/cups-1.3.8 )
	dbus? ( sys-apps/dbus )
	gtk? ( x11-libs/gtk+:3 )
	unicode? ( net-dns/libidn:= )
	X? ( x11-libs/libXt x11-libs/libXext )
"
BDEPEND="virtual/pkgconfig"
# bug #844115 for newer poppler-data dep
RDEPEND="
	${DEPEND}
	>=app-text/poppler-data-0.4.11-r2
	>=media-fonts/urw-fonts-2.4.9
	l10n_ja? ( media-fonts/kochi-substitute )
	l10n_ko? ( media-fonts/baekmuk-fonts )
	l10n_zh-CN? ( media-fonts/arphicfonts )
	l10n_zh-TW? ( media-fonts/arphicfonts )
"

PATCHES=(
	"${FILESDIR}"/${PN}-10.03.1-arm64-neon-tesseract.patch
)

src_prepare() {
	if [[ -n ${MY_PATCHSET} ]] ; then
		# apply various patches, many borrowed from Fedora
		# https://src.fedoraproject.org/rpms/ghostscript
		# and Debian
		# https://salsa.debian.org/printing-team/ghostscript/-/tree/debian/latest/debian/patches
		eapply "${WORKDIR}"/${MY_PATCHSET%%.tar*}
	fi

	default

	# Remove internal copies of various libraries
	rm -r cups/libs || die
	rm -r freetype || die
	rm -r jbig2dec || die
	rm -r jpeg || die
	rm -r lcms2mt || die
	rm -r libpng || die
	rm -r tiff || die
	rm -r zlib || die
	rm -r openjpeg || die
	# Remove internal CMaps (CMaps from poppler-data are used instead)
	rm -r Resource/CMap || die

	if ! use gtk ; then
		sed -e "s:\$(GSSOX)::" \
			-e "s:.*\$(GSSOX_XENAME)$::" \
			-i base/unix-dll.mak || die "sed failed"
	fi

	# Force the include dirs to a neutral location.
	sed -e "/^ZLIBDIR=/s:=.*:=${T}:" \
		-i configure.ac || die
	# Some files depend on zlib.h directly.  Redirect them. #573248
	# Also make sure to not define OPJ_STATIC to avoid linker errors due to
	# hidden symbols (https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=203327#c1)
	sed -e '/^zlib_h/s:=.*:=:' \
		-e 's|-DOPJ_STATIC ||' \
		-i base/lib.mak || die

	# Search path fix
	# put LDFLAGS after BINDIR, bug #383447
	sed -e "s:\$\(gsdatadir\)/lib:@datarootdir@/ghostscript/${PV}/$(get_libdir):" \
		-e "s:exdir=.*:exdir=@datarootdir@/doc/${PF}/examples:" \
		-e "s:docdir=.*:docdir=@datarootdir@/doc/${PF}/html:" \
		-e "s:GS_DOCDIR=.*:GS_DOCDIR=@datarootdir@/doc/${PF}/html:" \
		-e 's:-L$(BINDIR):& $(LDFLAGS):g' \
		-i Makefile.in base/*.mak || die "sed failed"

	# Remove incorrect symlink, bug 590384
	rm ijs/ltmain.sh || die
	eautoreconf

	cd ijs || die
	eautoreconf
}

src_configure() {
	# Unsupported upstream, bug #884841
	filter-lto

	# bug #943857
	# Build system passes CFLAGS to C++ compiler (bug #945826)
	tc-export CC
	CC+=" -std=gnu17"

	# bug #899952
	append-lfs-flags

	local FONTPATH
	for path in \
		"${EPREFIX}"/usr/share/fonts/urw-fonts \
		"${EPREFIX}"/usr/share/fonts/Type1 \
		"${EPREFIX}"/usr/share/fonts
	do
		FONTPATH="${FONTPATH}${FONTPATH:+:}${EPREFIX}${path}"
	done

	# Do not add --enable-dynamic here, it's not supported fully upstream
	# https://bugs.ghostscript.com/show_bug.cgi?id=705895
	# bug #884707
	#
	# leptonica and tesseract are bundled but modified upstream, like in
	# mujs/mupdf.
	PKGCONFIG=$(type -P $(tc-getPKG_CONFIG)) econf \
		--enable-freetype \
		--enable-fontconfig \
		--enable-openjpeg \
		--disable-compile-inits \
		--with-drivers=ALL \
		--with-fontpath="${FONTPATH}" \
		--with-ijs \
		--with-jbig2dec \
		--with-libpaper \
		--with-system-libtiff \
		$(use_enable cups) \
		$(use_enable dbus) \
		$(use_enable gtk) \
		$(use_enable cpu_flags_arm_neon neon) \
		$(use_with cups pdftoraster) \
		$(use_with unicode libidn) \
		$(use_with X x) \
		DARWIN_LDFLAGS_SO_PREFIX="${EPREFIX}/usr/lib/"

	cd "${S}/ijs" || die
	econf \
		--enable-shared \
		$(use_enable static-libs static)
}

src_compile() {
	emake so all
	emake -C ijs
}

src_install() {
	emake DESTDIR="${D}" install-so install

	# move gsc to gs, bug #343447
	# gsc collides with gambit, bug #253064
	mv -f "${ED}"/usr/bin/{gsc,gs} || die

	cd "${S}/ijs" || die
	emake DESTDIR="${D}" install

	# Sometimes the upstream versioning deviates from the tarball(!)
	# bug #844115#c32
	local my_gs_version=$(find "${ED}"/usr/share/ghostscript/ -maxdepth 1 -mindepth 1 -type d || die)
	my_gs_version=${my_gs_version##*/}

	# Install the CMaps from poppler-data properly, bug #409361
	dosym -r /usr/share/poppler/cMaps /usr/share/ghostscript/${my_gs_version}/Resource/CMap

	if ! use static-libs; then
		find "${ED}" -name '*.la' -delete || die
	fi
}

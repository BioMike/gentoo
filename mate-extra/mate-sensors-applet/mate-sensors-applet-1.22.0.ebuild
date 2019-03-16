# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

MATE_LA_PUNT="yes"

inherit mate

if [[ ${PV} != 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~x86"
fi

DESCRIPTION="MATE panel applet to display readings from hardware sensors"
LICENSE="GPL-2"
SLOT="0"

IUSE="+dbus hddtemp libnotify lm_sensors video_cards_nvidia"

COMMON_DEPEND=">=dev-libs/glib-2.50:2
	>=mate-base/mate-panel-1.17.0
	>=x11-libs/cairo-1.0.4
	x11-libs/gdk-pixbuf:2
	>=x11-libs/gtk+-3.22:3
	virtual/libintl
	hddtemp? (
		dbus? (
			>=dev-libs/dbus-glib-0.80
			>=dev-libs/libatasmart-0.16 )
		!dbus? ( >=app-admin/hddtemp-0.3_beta13 ) )
	libnotify? ( >=x11-libs/libnotify-0.7 )
	lm_sensors? ( sys-apps/lm_sensors )
	video_cards_nvidia? ( || (
		>=x11-drivers/nvidia-drivers-100.14.09:0[static-libs,tools]
	) )"

RDEPEND="${COMMON_DEPEND}"

DEPEND="${COMMON_DEPEND}
	app-text/rarian
	>=app-text/scrollkeeper-dtd-1:1.0
	app-text/yelp-tools
	>=dev-util/intltool-0.50.1:*
	sys-devel/gettext:*
	virtual/pkgconfig:*"

PDEPEND="hddtemp? ( dbus? ( sys-fs/udisks:0 ) )"

src_configure() {
	local udisks

	if use hddtemp && use dbus; then
		udisks="--enable-udisks"
	else
		udisks="--disable-udisks"
	fi

	mate_src_configure \
		--disable-static \
		--without-aticonfig \
		$(use_enable libnotify) \
		$(use_with lm_sensors libsensors) \
		$(use_with video_cards_nvidia nvidia) \
		${udisks}
}

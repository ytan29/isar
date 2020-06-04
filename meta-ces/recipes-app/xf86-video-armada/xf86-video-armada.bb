DESCRIPTION = "Xorg video driver for Marvell Armada DRM and Freescale i.MX"

LICENSE = "mit"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/COPYING;md5=036ec96f21e8bbe9f7e32ac16cac0889"

DEPENDS += "libdrm-armada-dev"

PV = "unstable"

SRC_URI = "git://github.com/ilbers/xf86-video-armada.git;branch=unstable;protocol=http;destsuffix=${P}"
SRCREV = "${AUTOREV}"

inherit dpkg
DESCRIPTION = "Xorg video driver for Marvell Armada DRM and Freescale i.MX"

LICENSE = "mit"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/COPYING;md5=036ec96f21e8bbe9f7e32ac16cac0889"

DEPENDS += "libdrm-armada-dev"

PV = "unstable"

SRC_URI = "git://github.com/ilbers/xf86-video-armada.git;branch=unstable;protocol=http;destsuffix=${P}"
SRCREV = "82aa321c96569078f0053ba74247ab9205953c40"

inherit dpkg
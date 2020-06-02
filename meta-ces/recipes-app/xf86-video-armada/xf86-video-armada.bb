DESCRIPTION = "Xorg video driver for Marvell Armada DRM and Freescale i.MX"

LICENSE = "mit"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/COPYING;md5=036ec96f21e8bbe9f7e32ac16cac0889"

PV = "unstable-devel+34a7272"

SRC_URI = "git://git.arm.linux.org.uk/cgit/xf86-video-armada.git;branch=unstable-devel;protocol=http;destsuffix=${P}"
SRCREV = "34a7272573431a9a0fabb94012f902198a3ac9a7"

inherit dpkg
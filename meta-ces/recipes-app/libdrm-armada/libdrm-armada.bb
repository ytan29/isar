DESCRIPTION = "Marvell Armada libdrm buffer object management module"

LICENSE = "mit"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/COPYING;md5=036ec96f21e8bbe9f7e32ac16cac0889"

PV = "master+607c697"

SRC_URI = "git://git.arm.linux.org.uk/cgit/libdrm-armada.git;protocol=http;destsuffix=${P}"
SRCREV = "607c697d7c403356601cd0d5fa6407b61a45e8ed"

inherit dpkg
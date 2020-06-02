DESCRIPTION = "Linux kernel for CES boards"

LICENSE = "lgpl-2.1"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/LICENSES/preferred/LGPLv2.1;md5=b370887980db5dd40659b50909238dbd"

PV = "4.9.17-0a4b382"

SRC_URI = "git://github.com/software-celo/linux-fslc.git;protocol=https;destsuffix=${P}"
SRCREV = "0a4b382d1d816bdbfc13446c0e6d1c60539fc7e4"

inherit dpkg
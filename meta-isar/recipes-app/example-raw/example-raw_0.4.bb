# Sample application using dpkg-raw, which turns a folder (${D}) of
# files into a .deb
#
# This software is a part of ISAR.

inherit dpkg-raw

DESCRIPTION = "Sample application for ISAR"
MAINTAINER = "Your name here <you@domain.com>"
DEBIAN_DEPENDS = "apt (>= 0.4.2), passwd"

SRC_URI = " \
    git://github.com/WiseLord/example-raw.git;protocol=https \
    file://0001-Add-a-version-number-to-the-binary.patch \
    file://README \
    file://postinst \
    file://rules"
SRCREV="1c142e04e498f20928a4b034d8b11fda2b69c6d7"

S = "${WORKDIR}/git"

do_install() {
    bbnote "Putting source files into package"
    cp -r ${S}/src/* -t ${D}
}

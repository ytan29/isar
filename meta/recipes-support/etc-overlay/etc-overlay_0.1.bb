# Create a overlay for /etc to freeze a default configuration
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT


DESCRIPTION = "overlay systemd-mount"

DEBIAN_DEPENDS = "systemd"

SRC_URI = "file://postinst \
           file://postrm \
           file://etc.mount \
           file://ovl.mount.tmpl \
           file://overlay-parse-etc.service \
           file://etc-hostname.service"

FS_COMMIT_INTERVAL ?= "20"

TEMPLATE_VARS  += "FS_COMMIT_INTERVAL"
TEMPLATE_FILES += "ovl.mount.tmpl"

inherit dpkg-raw

do_install() {
    install -m 0755 -d ${D}/ovl
    touch ${D}/ovl/.keep

    TARGET=${D}/lib/systemd/system
    install -m 0755 -d ${TARGET}
    install -m 0644 ${WORKDIR}/etc.mount ${TARGET}/etc.mount
    install -m 0644 ${WORKDIR}/ovl.mount ${TARGET}/ovl.mount
    install -m 0644 ${WORKDIR}/overlay-parse-etc.service  ${TARGET}/overlay-parse-etc.service
    install -m 0644 ${WORKDIR}/etc-hostname.service ${TARGET}/etc-hostname.service
}

addtask do_install after do_transform_template

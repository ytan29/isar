# Sample Skel modifiction for ISAR
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Sample Skel modifiction for ISAR"
MAINTAINER = "Your name here <you@domain.com>"


inherit dpkg-raw

do_install() {
	bbnote "Create a fake extra skel"
	echo "# empty config file" > ${WORKDIR}/${PN}.conf
	install -v -d ${D}/etc/extra-skel
	install -v -m 644 ${WORKDIR}/${PN}.conf ${D}/etc/extra-skel/${PN}.conf
}
# Base image recipe for ISAR
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit image

IMAGE_INSTALL += "example-user-skel"

# create a user isar with no password and default home
USERS += "isar"
USER_isar[password] = ""
USER_isar[uid] = "1000"
USER_isar[groups] = "audio video "
USER_isar[shell] = "/bin/bash"
USER_isar[flags] = "allow-empty-password create-home"
# create a user isarskel with no password and home generated from /etc/extra-skel
USERS += "isarskel"
USER_isarskel[password] = ""
USER_isarskel[uid] = "2000"
USER_isarskel[groups] = "audio video "
USER_isarskel[shell] = "/bin/bash"
USER_isarskel[skel] = "/etc/extra-skel"
USER_isarskel[flags] = "allow-empty-password create-home"
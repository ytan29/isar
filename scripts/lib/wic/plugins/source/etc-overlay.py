# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-
#
# Copyright (c) 2014, Intel Corporation.
# Copyright (c) 2018, Siemens AG.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# DESCRIPTION
# This implements the 'etc-overlay' source plugin class for 'wic'
#
# AUTHORS
# Tom Zanussi <tom.zanussi (at] linux.intel.com>
# Andreas Reichel <andreas.reichel.ext (at] siemens.com>
# Quirin Gylstorff <quirin.gylstorff [at] siemens.com>


import logging

msger = logging.getLogger('wic')

from wic.pluginbase import SourcePlugin
from wic.utils.misc import exec_cmd,BOOTDD_EXTRA_SPACE

class EtcOverlayPlugin(SourcePlugin):
    """
    Create an overlay file system scheme for etc
    """

    name = 'etc-overlay'

    @classmethod
    def do_prepare_partition(cls, part, source_params, creator, cr_workdir,
                             oe_builddir, deploy_dir, kernel_dir,
                             rootfs_dir, native_sysroot):

        part_rootfs_dir = "%s/disk/%s.%s" % (cr_workdir,
                                             part.label,
                                             part.lineno)
        create_dir_cmd = "install -d %s" % part_rootfs_dir
        exec_cmd(create_dir_cmd)

        exec_cmd("install -m 0755 -d %s/etc" % part_rootfs_dir)
        exec_cmd("install -m 0755 -d %s/.atomic" % part_rootfs_dir)

        blocks = 16
        extra_blocks = part.get_extra_block_count(blocks)
        if extra_blocks < BOOTDD_EXTRA_SPACE:
            extra_blocks = BOOTDD_EXTRA_SPACE
        blocks += extra_blocks
        blocks = blocks + (16 - (blocks % 16))

        msger.debug("Added %d extra blocks to %s to get to %d total blocks",
                    extra_blocks, part.mountpoint, blocks)

        # ext4 image, created by mkfs.ext4
        etcovlimg = "%s/%s.%s.img" % (cr_workdir, part.label, part.lineno)
        partfs_cmd = "dd if=/dev/zero of=%s bs=512 count=%d" % (etcovlimg,
                                                                blocks)
        exec_cmd(partfs_cmd)

        partfs_cmd = "mkfs.ext4 %s -d %s" % (etcovlimg, part_rootfs_dir)
        exec_cmd(partfs_cmd)

        chmod_cmd = "chmod 644 %s" % etcovlimg
        exec_cmd(chmod_cmd)

        du_cmd = "du -Lbks %s" % etcovlimg
        etcovlimg_size = int(exec_cmd(du_cmd).split()[0])

        part.size = etcovlimg_size
        part.source_file = etcovlimg

# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

INITRAMFS_MODULES ?= "most"
INITRAMFS_BUSYBOX ?= "auto"
INITRAMFS_COMPRESS ?= "gzip"
INITRAMFS_KEYMAP ?= "n"
INITRAMFS_NET_DEVICE ?= ""
INITRAMFS_NFSROOT ?= "auto"
INITRAMFS_RUNSIZE ?= "10%"
INITRAMFS_ROOT ?= ""
INITRAMFS_MODULE_LIST ?= ""
update_initramfs_modules() {
    for modname in ${INITRAMFS_MODULE_LIST}; do
        sudo -E tee --append '${ROOTFSDIR}/etc/initramfs-tools/modules' << EOF
${modname}
EOF
    done
}
update_initramfs_config() {
    sudo -E tee ${ROOTFSDIR}/etc/initramfs-tools/initramfs.conf << EOF
MODULES=${INITRAMFS_MODULES}
BUSYBOX=${INITRAMFS_BUSYBOX}
COMPRESS=${INITRAMFS_COMPRESS}
KEYMAP=${INITRAMFS_KEYMAP}
DEVICE=${INITRAMFS_NET_DEVICE}
NFSROOT=${INITRAMFS_NFSROOT}
RUNSIZE=${INITRAMFS_RUNSIZE}
ROOT=${INITRAMFS_ROOT}
EOF
}

do_update_initramfs() {
    update_initramfs_modules
    update_initramfs_config
    export KERNEL_VERSION=$(ls ${ROOTFSDIR}/lib/modules)
    bbplain kernel_version: ${KERNEL_VERSION}
    sudo -E chroot '${ROOTFSDIR}' \
        mkinitramfs -v -k -o /boot/initrd.img-${KERNEL_VERSION} ${KERNEL_VERSION}
}

addtask update_initramfs before do_copy_boot_files after do_rootfs_install

# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

# Install Debian packages, that were built from sources
do_populate() {
    if [ -n "${IMAGE_INSTALL}" ]; then
        sudo mkdir -p ${S}/deb

        for p in ${IMAGE_INSTALL}; do
            sudo cp ${DEPLOY_DIR_DEB}/${p}_*.deb ${S}/deb
        done

        sudo chroot ${S} /usr/bin/dpkg -i -R /deb

        sudo rm -rf ${S}/deb
    fi
}

addtask populate before do_build
do_populate[deptask] = "do_install"

# Extra space for rootfs in MB
ROOTFS_EXTRA ?= "64"

# Generate ext4 filesystem image
do_image() {
    mkdir -p ${DEPLOY_DIR_IMAGE}

    rm -f ${DEPLOY_DIR_IMAGE}/${PN}.ext4.img

    ROOTFS_SIZE=`sudo du -sm ${S} |  awk '{print $1 + ${ROOTFS_EXTRA};}'`
    dd if=/dev/zero of=${DEPLOY_DIR_IMAGE}/${PN}.ext4.img bs=1M count=${ROOTFS_SIZE}

    sudo mkfs.ext4 -F ${DEPLOY_DIR_IMAGE}/${PN}.ext4.img

    mkdir -p ${WORKDIR}/mnt
    sudo mount -o loop ${DEPLOY_DIR_IMAGE}/${PN}.ext4.img ${WORKDIR}/mnt
    sudo cp -r ${S}/* ${WORKDIR}/mnt
    sudo umount ${WORKDIR}/mnt
    rm -r ${WORKDIR}/mnt

    if [ -n "${KERNEL_IMAGE}" ]; then
        cp ${S}/boot/${KERNEL_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi

    if [ -n "${INITRD_IMAGE}" ]; then
        cp ${S}/boot/${INITRD_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi
}

addtask image before do_build after do_populate
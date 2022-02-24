# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

S = "${WORKDIR}/git"

PATCHTOOL ?= "git"

GBP_DEPENDS ?= "git-buildpackage pristine-tar"
GBP_EXTRA_OPTIONS ?= "--git-pristine-tar"

do_install_builddeps_append() {
    ${SCRIPTSDIR}/debrepo \
        --workdir="${TMPDIR}/debrepo/${BASE_DISTRO}-${BASE_DISTRO_CODENAME}" \
        ${GBP_DEPENDS}
    dpkg_do_mounts
    sudo -E chroot '${BUILDCHROOT_DIR}' /usr/bin/apt-get update \
        -o Dir::Etc::SourceList="sources.list.d/base-apt.list" \
        -o Dir::Etc::SourceParts="-" \
        -o APT::Get::List-Cleanup="0"
    distro="${DISTRO}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
       distro="${HOST_DISTRO}"
    fi
    deb_dl_dir_import "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} \
        apt-get install -y -o Debug::pkgProblemResolver=yes \
                        --no-install-recommends --download-only ${GBP_DEPENDS}
    deb_dl_dir_export "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} \
        apt-get install -y -o Debug::pkgProblemResolver=yes \
                        --no-install-recommends ${GBP_DEPENDS}
    dpkg_undo_mounts
}

dpkg_runbuild_prepend() {
    export GBP_PREFIX="gbp buildpackage --git-ignore-new ${GBP_EXTRA_OPTIONS} --git-builder="
}

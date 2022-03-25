# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

PACKAGE_ARCH ?= "${DISTRO_ARCH}"

# Install build dependencies for package
do_install_builddeps() {
    ${SCRIPTSDIR}/debrepo \
        --workdir="${TMPDIR}/debrepo/${BASE_DISTRO}-${BASE_DISTRO_CODENAME}" \
        --controlfile="${WORKDIR}/${PPS}/debian/control"
    dpkg_do_mounts
    sudo -E chroot '${BUILDCHROOT_DIR}' /usr/bin/apt-get update \
        -o Dir::Etc::SourceList="sources.list.d/base-apt.list" \
        -o Dir::Etc::SourceParts="-" \
        -o APT::Get::List-Cleanup="0"
    E="${@ isar_export_proxies(d)}"
    export DEB_BUILD_OPTIONS="${@ isar_deb_build_options(d)}"
    export DEB_BUILD_PROFILES="${@ isar_deb_build_profiles(d)}"
    distro="${DISTRO}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
        distro="${HOST_DISTRO}"
    fi

    deb_dl_dir_import "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh \
        ${PP}/${PPS} ${PACKAGE_ARCH} --download-only
    deb_dl_dir_export "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh \
        ${PP}/${PPS} ${PACKAGE_ARCH}
    dpkg_undo_mounts
}

addtask install_builddeps after do_prepare_build before do_dpkg_build
do_install_builddeps[depends] += "isar-apt:do_cache_config"
# apt and reprepro may not run in parallel, acquire the Isar lock
do_install_builddeps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

addtask devshell after do_install_builddeps

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ isar_export_proxies(d)}"
    E="${@ isar_export_ccache(d)}"
    export DEB_BUILD_OPTIONS="${@ isar_deb_build_options(d)}"
    export DEB_BUILD_PROFILES="${@ isar_deb_build_profiles(d)}"
    export PARALLEL_MAKE="${PARALLEL_MAKE}"
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
         /isar/build.sh ${PP}/${PPS} ${PACKAGE_ARCH}
}

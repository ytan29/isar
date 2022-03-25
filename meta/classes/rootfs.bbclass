# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020

inherit deb-dl-dir

ROOTFS_ARCH ?= "${DISTRO_ARCH}"
ROOTFS_DISTRO ?= "${DISTRO}"
ROOTFS_PACKAGES ?= ""

# Features of the rootfs creation:
# available features are:
# 'clean-package-cache' - delete package cache from rootfs
# 'generate-manifest' - generate a package manifest of the rootfs into ${ROOTFS_MANIFEST_DEPLOY_DIR}
# 'export-dpkg-status' - exports /var/lib/dpkg/status file to ${ROOTFS_DPKGSTATUS_DEPLOY_DIR}
# 'clean-log-files' - delete log files that are not owned by packages
ROOTFS_FEATURES ?= ""

ROOTFS_APT_ARGS="install --yes -o Debug::pkgProblemResolver=yes"

ROOTFS_CLEAN_FILES="/etc/hostname /etc/resolv.conf"

ROOTFS_PACKAGE_SUFFIX ?= "${PN}-${DISTRO}-${DISTRO_ARCH}"

# Useful environment variables:
export E = "${@ isar_export_proxies(d)}"
export DEBIAN_FRONTEND = "noninteractive"
# To avoid Perl locale warnings:
export LANG = "C"
export LANGUAGE = "C"
export LC_ALL = "C"

rootfs_do_mounts[weight] = "3"
rootfs_do_mounts() {
    sudo -s <<'EOSUDO'
        set -e
        mountpoint -q '${ROOTFSDIR}/dev' || \
            mount --rbind /dev '${ROOTFSDIR}/dev'
        mount --make-rslave '${ROOTFSDIR}/dev'
        mountpoint -q '${ROOTFSDIR}/proc' || \
            mount -t proc none '${ROOTFSDIR}/proc'
        mountpoint -q '${ROOTFSDIR}/sys' || \
            mount --rbind /sys '${ROOTFSDIR}/sys'
        mount --make-rslave '${ROOTFSDIR}/sys'

        # Mount isar-apt if the directory does not exist or if it is empty
        # This prevents overwriting something that was copied there
        if [ ! -e '${ROOTFSDIR}/isar-apt' ] || \
           [ "$(find '${ROOTFSDIR}/isar-apt' -maxdepth 1 -mindepth 1 | wc -l)" = "0" ]
        then
            mkdir -p '${ROOTFSDIR}/isar-apt'
            mountpoint -q '${ROOTFSDIR}/isar-apt' || \
                mount --bind '${REPO_ISAR_DIR}/${DISTRO}' '${ROOTFSDIR}/isar-apt'
        fi

        mkdir -p '${ROOTFSDIR}/base-apt'
        mountpoint -q '${ROOTFSDIR}/base-apt' || \
            mount --bind '${REPO_BASE_DIR}' '${ROOTFSDIR}/base-apt'

EOSUDO
}

rootfs_do_qemu() {
    if [ '${@repr(d.getVar('ROOTFS_ARCH') == d.getVar('HOST_ARCH'))}' = 'False' ]
    then
        test -e '${ROOTFSDIR}/usr/bin/qemu-${QEMU_ARCH}-static' || \
            sudo cp '/usr/bin/qemu-${QEMU_ARCH}-static' '${ROOTFSDIR}/usr/bin/qemu-${QEMU_ARCH}-static'
    fi
}

BOOTSTRAP_SRC = "${DEPLOY_DIR_BOOTSTRAP}/${ROOTFS_DISTRO}-host_${DISTRO}-${DISTRO_ARCH}"
BOOTSTRAP_SRC_${ROOTFS_ARCH} = "${DEPLOY_DIR_BOOTSTRAP}/${ROOTFS_DISTRO}-${ROOTFS_ARCH}"

rootfs_prepare[weight] = "25"
rootfs_prepare(){
    sudo cp -Trpfx '${BOOTSTRAP_SRC}/' '${ROOTFSDIR}'
}

ROOTFS_CONFIGURE_COMMAND += "rootfs_configure_isar_apt"
rootfs_configure_isar_apt[weight] = "2"
rootfs_configure_isar_apt() {
    sudo -s <<'EOSUDO'
    set -e

    mkdir -p '${ROOTFSDIR}/etc/apt/sources.list.d'
    echo 'deb [trusted=yes] file:///isar-apt ${DEBDISTRONAME} main' > \
        '${ROOTFSDIR}/etc/apt/sources.list.d/isar-apt.list'

    mkdir -p '${ROOTFSDIR}/etc/apt/preferences.d'
    cat << EOF > '${ROOTFSDIR}/etc/apt/preferences.d/isar-apt'
Package: *
Pin: release n=${DEBDISTRONAME}
Pin-Priority: 1000
EOF
EOSUDO
}

ROOTFS_CONFIGURE_COMMAND += "rootfs_configure_apt"
rootfs_configure_apt[weight] = "2"
rootfs_configure_apt() {
    sudo -s <<'EOSUDO'
    set -e

    mkdir -p '${ROOTFSDIR}/etc/apt/apt.conf.d'
    {
        echo 'APT::Acquire::Retries "3";'
        echo 'APT::Install-Recommends "0";'
        echo 'APT::Install-Suggests "0";'
    } > '${ROOTFSDIR}/etc/apt/apt.conf.d/50isar'
EOSUDO
}


ROOTFS_INSTALL_COMMAND += "rootfs_install_pkgs_update"
rootfs_install_pkgs_update[weight] = "5"
rootfs_install_pkgs_update[isar-apt-lock] = "acquire-before"
rootfs_install_pkgs_update() {
    sudo -E chroot '${ROOTFSDIR}' /usr/bin/apt-get update \
        -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
        -o Dir::Etc::SourceParts="-" \
        -o APT::Get::List-Cleanup="0"
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_resolvconf"
rootfs_install_resolvconf[weight] = "1"
rootfs_install_resolvconf() {
    if [ "${@repr(bb.utils.to_boolean(d.getVar('BB_NO_NETWORK')))}" != "True" ]
    then
        sudo cp -rL /etc/resolv.conf '${ROOTFSDIR}/etc'
    fi
}

ROOTFS_INSTALL_COMMAND += "rootfs_import_package_cache"
rootfs_import_package_cache[weight] = "5"
rootfs_import_package_cache() {
    deb_dl_dir_import ${ROOTFSDIR} ${ROOTFS_DISTRO}
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_pkgs_download"
rootfs_install_pkgs_download[weight] = "600"
rootfs_install_pkgs_download[isar-apt-lock] = "release-after"
rootfs_install_pkgs_download() {
    sudo -E chroot '${ROOTFSDIR}' \
        /usr/bin/apt-get ${ROOTFS_APT_ARGS} --download-only ${ROOTFS_PACKAGES}
}

ROOTFS_INSTALL_COMMAND_BEFORE_EXPORT ??= ""
ROOTFS_INSTALL_COMMAND += "${ROOTFS_INSTALL_COMMAND_BEFORE_EXPORT}"

ROOTFS_INSTALL_COMMAND += "rootfs_export_package_cache"
rootfs_export_package_cache[weight] = "5"
rootfs_export_package_cache() {
    deb_dl_dir_export ${ROOTFSDIR} ${ROOTFS_DISTRO}
}

ROOTFS_INSTALL_COMMAND += "${@ 'rootfs_install_clean_files' if (d.getVar('ROOTFS_CLEAN_FILES') or '').strip() else ''}"
rootfs_install_clean_files[weight] = "2"
rootfs_install_clean_files() {
    sudo -E chroot '${ROOTFSDIR}' \
        /bin/rm -f ${ROOTFS_CLEAN_FILES}
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_pkgs_install"
rootfs_install_pkgs_install[weight] = "8000"
rootfs_install_pkgs_install() {
    sudo -E chroot "${ROOTFSDIR}" \
        /usr/bin/apt-get ${ROOTFS_APT_ARGS} ${ROOTFS_PACKAGES}
}

do_rootfs_install[root_cleandirs] = "${ROOTFSDIR}"
do_rootfs_install[vardeps] += "${ROOTFS_CONFIGURE_COMMAND} ${ROOTFS_INSTALL_COMMAND}"
do_rootfs_install[depends] = "isar-bootstrap-${@'target' if d.getVar('ROOTFS_ARCH') == d.getVar('DISTRO_ARCH') else 'host'}:do_build"
do_rootfs_install[recrdeptask] = "do_deploy_deb"
python do_rootfs_install() {
    configure_cmds = (d.getVar("ROOTFS_CONFIGURE_COMMAND", True) or "").split()
    install_cmds = (d.getVar("ROOTFS_INSTALL_COMMAND", True) or "").split()

    # Mount after configure commands, so that they have time to copy
    # 'isar-apt' (sdkchroot):
    cmds = ['rootfs_prepare'] + configure_cmds + ['rootfs_do_mounts'] + install_cmds

    # NOTE: The weights specify how long each task takes in seconds and are used
    # by the MultiStageProgressReporter to render a progress bar for this task.
    # To printout the measured weights on a run, add `debug=True` as a parameter
    # the MultiStageProgressReporter constructor.
    stage_weights = [int(d.getVarFlag(i, 'weight', True) or "20")
                     for i in cmds]

    progress_reporter = bb.progress.MultiStageProgressReporter(d, stage_weights)

    for cmd in cmds:
        progress_reporter.next_stage()

        if (d.getVarFlag(cmd, 'isar-apt-lock') or "") == "acquire-before":
            lock = bb.utils.lockfile(d.getVar("REPO_ISAR_DIR") + "/isar.lock",
                                     shared=True)

        bb.build.exec_func(cmd, d)

        if (d.getVarFlag(cmd, 'isar-apt-lock') or "") == "release-after":
            bb.utils.unlockfile(lock)
    progress_reporter.finish()
}
addtask rootfs_install before do_rootfs_postprocess after do_unpack

cache_deb_src() {
    if [ -e "${ROOTFSDIR}"/etc/resolv.conf ] ||
       [ -h "${ROOTFSDIR}"/etc/resolv.conf ]; then
        sudo mv "${ROOTFSDIR}"/etc/resolv.conf "${ROOTFSDIR}"/etc/resolv.conf.isar
    fi
    rootfs_install_resolvconf
    # Note: ISAR updates the apt state information(apt-get update) only once during bootstrap and
    # relies on that through out the build. Copy that state information instead of apt-get update
    # which generates a new state from upstream.
    sudo cp -Trpn "${BOOTSTRAP_SRC}/var/lib/apt/lists/" "${ROOTFSDIR}/var/lib/apt/lists/"

    deb_dl_dir_import ${ROOTFSDIR} ${ROOTFS_DISTRO}
    debsrc_download ${ROOTFSDIR} ${ROOTFS_DISTRO}

    sudo rm -f "${ROOTFSDIR}"/etc/resolv.conf
    if [ -e "${ROOTFSDIR}"/etc/resolv.conf.isar ] ||
       [ -h "${ROOTFSDIR}"/etc/resolv.conf.isar ]; then
        sudo mv "${ROOTFSDIR}"/etc/resolv.conf.isar "${ROOTFSDIR}"/etc/resolv.conf
    fi
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'clean-package-cache', 'rootfs_postprocess_clean_package_cache', '', d)}"
rootfs_postprocess_clean_package_cache() {
    sudo -E chroot '${ROOTFSDIR}' \
        /usr/bin/apt-get clean
    sudo rm -rf "${ROOTFSDIR}/var/lib/apt/lists/"*
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'clean-log-files', 'rootfs_postprocess_clean_log_files', '', d)}"
rootfs_postprocess_clean_log_files() {
    # Delete log files that are not owned by packages
    sudo -E chroot '${ROOTFSDIR}' \
        /usr/bin/find /var/log/ -type f \
        -exec sh -c '! dpkg -S {} > /dev/null 2>&1' ';' \
        -exec rm -f {} ';'
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'generate-manifest', 'rootfs_generate_manifest', '', d)}"
rootfs_generate_manifest () {
    mkdir -p ${ROOTFS_MANIFEST_DEPLOY_DIR}
    sudo -E chroot --userspec=$(id -u):$(id -g) '${ROOTFSDIR}' \
        dpkg-query -W -f \
            '${source:Package}|${source:Version}|${binary:Package}|${Version}\n' > \
        '${ROOTFS_MANIFEST_DEPLOY_DIR}'/'${ROOTFS_PACKAGE_SUFFIX}'.manifest
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'export-dpkg-status', 'rootfs_export_dpkg_status', '', d)}"
rootfs_export_dpkg_status() {
    mkdir -p ${ROOTFS_DPKGSTATUS_DEPLOY_DIR}
    cp '${ROOTFSDIR}'/var/lib/dpkg/status \
       '${ROOTFS_DPKGSTATUS_DEPLOY_DIR}'/'${ROOTFS_PACKAGE_SUFFIX}'.dpkg_status
}

do_rootfs_postprocess[vardeps] = "${ROOTFS_POSTPROCESS_COMMAND}"
python do_rootfs_postprocess() {
    # Take care that its correctly mounted:
    bb.build.exec_func('rootfs_do_mounts', d)
    # Take care that qemu-*-static is available, since it could have been
    # removed on a previous execution of this task:
    bb.build.exec_func('rootfs_do_qemu', d)

    progress_reporter = bb.progress.ProgressHandler(d)
    progress_reporter.update(0)

    cmds = d.getVar("ROOTFS_POSTPROCESS_COMMAND")
    if cmds is None or not cmds.strip():
        return
    cmds = cmds.split()
    for i, cmd in enumerate(cmds):
        bb.build.exec_func(cmd, d)
        progress_reporter.update(int(i / len(cmds) * 100))
}
addtask rootfs_postprocess before do_rootfs after do_unpack

python do_rootfs() {
    """Virtual task"""
    pass
}
addtask rootfs before do_build

do_rootfs_postprocess[depends] = "base-apt:do_cache isar-apt:do_cache_config"

SSTATETASKS += "do_rootfs_install"
SSTATECREATEFUNCS += "rootfs_install_sstate_prepare"
SSTATEPOSTINSTFUNCS += "rootfs_install_sstate_finalize"

# the rootfs is owned by root, so we need some sudoing to pack and unpack
rootfs_install_sstate_prepare() {
    # this runs in SSTATE_BUILDDIR, which will be deleted automatically
    # tar --one-file-system will cross bind-mounts to the same filesystem,
    # so we use some mount magic to prevent that
    mkdir -p ${WORKDIR}/mnt/rootfs
    sudo mount --bind ${WORKDIR}/rootfs ${WORKDIR}/mnt/rootfs -o ro
    sudo tar -C ${WORKDIR}/mnt -cpf rootfs.tar --one-file-system rootfs
    sudo umount ${WORKDIR}/mnt/rootfs
    sudo chown $(id -u):$(id -g) rootfs.tar
}
do_rootfs_install_sstate_prepare[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"

rootfs_install_sstate_finalize() {
    # this runs in SSTATE_INSTDIR
    # - after building the rootfs, the tar won't be there, but we also don't need to unpack
    # - after restoring from cache, there will be a tar which we unpack and then delete
    if [ -f rootfs.tar ]; then
        sudo tar -C ${WORKDIR} -xpf rootfs.tar
        rm rootfs.tar
    fi
}

python do_rootfs_install_setscene() {
    sstate_setscene(d)
}
addtask do_rootfs_install_setscene

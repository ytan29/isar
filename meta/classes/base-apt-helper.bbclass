# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH

DISTRO_NAME ?= "${@ d.getVar('DISTRO', True).split('-')[0]}"
DISTRO_SUITE ?= "${@ d.getVar('DISTRO', True).split('-')[1]}"

populate_base_apt() {
    search_dir=$1

    for package in $(find $search_dir -name '*.deb'); do
        # NOTE: due to packages stored by reprepro are not modified, we can
        # use search by filename to check if package is already in repo. In
        # addition, m5sums could be compared to ensure, that package is the
        # same and should not be overwritten. This method is easier and more
        # robust than querying reprepro by name.

        # Check if this package is taken from Isar-apt, if so - ingore it.
        isar_package=$(find ${DEPLOY_DIR_APT}/${DISTRO} -name $package)
        if [ -n "$isar_package" ]; then
            # Check if MD5 sums are iendtical. This helps to avoid the case
            # when packages is overriden from another repo.
            md1=$(md5sum $package)
            md2=$(md5sum $isar_package)
            if [ "$md1" = "$md2" ]; then
                continue
            fi
        fi

        # Check if this package is already in base-apt
        isar_package=$(find ${BASE_APT_DIR}/${DISTRO_NAME} -name $package)
        if [ -n "$isar_package" ]; then
            md1=$(md5sum $package)
            md2=$(md5sum $isar_package)
            if [ "$md1" = "$md2" ]; then
                continue
            fi

            # md5sum differs, so remove the package from base-apt
            name=$(basename $package | cut -d '_' -f 1)
            reprepro -b ${BASE_APT_DIR}/${DISTRO_NAME} \
                     --dbdir ${BASE_APT_DB}/${DISTRO_NAME} \
                     -C main -A ${DISTRO_ARCH} \
                     remove ${DISTRO_SUITE} \
                     $name
        fi

        reprepro -b ${BASE_APT_DIR}/${DISTRO_NAME} \
                 --dbdir ${BASE_APT_DB}/${DISTRO_NAME} \
                 -C main \
                 includedeb ${DISTRO_SUITE} \
                 $package
    done
}

# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH

SRC_URI = "file://distributions.in"

inherit base-apt-helper

CACHE_CONF_DIR = "${BASE_APT_DIR}/${DISTRO_NAME}/conf"
do_cache_config[dirs] = "${CACHE_CONF_DIR}"
do_cache_config[stamp-extra-info] = "${DISTRO}"
do_cache_config[lockfiles] = "${BASE_APT_DIR}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    if [ ! -e "${CACHE_CONF_DIR}/distributions" ]; then
        sed -e "s#{DISTRO_NAME}#"${DISTRO_SUITE}"#g" \
            ${WORKDIR}/distributions.in > ${CACHE_CONF_DIR}/distributions
    fi

    path_cache="${BASE_APT_DIR}/${DISTRO_NAME}"
    path_databases="${BASE_APT_DB}/${DISTRO_NAME}"

    if [ ! -d "${path_databases}" ]; then
        reprepro -b ${path_cache} \
                 --dbdir ${path_databases} \
                 export ${DISTRO_SUITE}
    fi
}

addtask cache_config after do_build

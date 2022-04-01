DESCRIPTION = "Linux Kernel for Intel SoCFPGA"
LICENSE = "GPLv2"


KERNEL_REPO ?= "git://github.com/altera-opensource/linux-socfpga.git"

# ECI-MOD: Just use GIT as-is
#KERNEL_PROT ?= "https"

# Kernel CONFIG_LOCALVERSION
LINUX_VERSION_EXTENSION ?= "-altera"

# Build branch name
LINUX_VERSION_PREFIX ?= "socfpga-"
LINUX_VERSION_SUFFIX ?= ""
LINUX_VERSION ?= "4.0"

SRCREV ?= "${AUTOREV}"
SRCREV_machine ?= "${AUTOREV}"

# ECI-MOD: ISAR doesn't need this customization, PV will just be recipe version as-is 5.10
#PV = "${LINUX_VERSION}${LINUX_VERSION_SUFFIX}"
#PV_append = "+git${SRCPV}"

KBRANCH ?= "${LINUX_VERSION_PREFIX}${LINUX_VERSION}${LINUX_VERSION_SUFFIX}"

SRC_URI += " \
	${KERNEL_REPO};branch=${KBRANCH};destsuffix=${P} \
	file://socfpga_defconfig "

# ECI-MOD: isar distro instead of poky
#require recipes-kernel/linux/linux-yocto.inc
require recipes-kernel/linux/linux-custom.inc

# ECI-MOD: Follows linux-mainline to define manual defconfig
KERNEL_DEFCONFIG_agilex = "socfpga_defconfig"

# ECI-MOD: Replaced with KERNEL_DEFCONFIG above
#KBUILD_DEFCONFIG ?= "socfpga_defconfig"
#KCONFIG_MODE ?= "--alldefconfig"

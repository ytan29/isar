LINUX_VERSION = "5.10.60"
LINUX_VERSION_SUFFIX = "-lts"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

# ECI-MOD: Not required since linux-socfpga.inc uses AUTOREV
#SRCREV = "c35d63f9c7e450605ef20834d2613f845f0c3388"

include linux-socfpga.inc

# ECI-MOD:  No usage of SRC_URI_append_agilex
#FILESEXTRAPATHS_prepend := "${THISDIR}/config:"

#SRC_URI_append_n5x = " file://jffs2.scc file://gpio_sys.scc "
#SRC_URI_append_stratix10 = " file://jffs2.scc file://gpio_sys.scc "
#SRC_URI_append_arria10 = " file://lbdaf.scc file://jffs2.scc file://gpio_sys.scc "
#SRC_URI_append_cyclone5 = " file://lbdaf.scc "
#SRC_URI_append_arria5 = " file://lbdaf.scc "

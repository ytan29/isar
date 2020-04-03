# This software is a part of ISAR.
# Copyright (C) 2019-2020 Siemens AG
#
# This class allows to generate images for vmware and virtualbox
#

inherit buildchroot
inherit wic-img
IMAGER_INSTALL += "qemu-utils gawk uuid-runtime"
OVA_NAME ?= "${IMAGE_FULLNAME}"
OVA_MEMORY ?= "8192"
OVA_NUMBER_OF_CPU ?= "4"
OVA_VRAM ?= "64"
OVA_FIRMWARE ?= "efi"
OVA_ACPI ?= "true"
OVA_3D_ACCEL ?= "false"
OVA_CLIPBOARD ?= "bidirectional"
SOURCE_IMAGE_FILE ?= "${IMAGE_FULLNAME}.wic.img"
OVA_SHA_ALG ?= "1"
VIRTUAL_MACHINE_IMAGE_TYPE ?= "vmdk"
VIRTUAL_MACHINE_IMAGE_FILE ?= "${IMAGE_FULLNAME}-disk1.${VIRTUAL_MACHINE_IMAGE_TYPE}"
VIRTUAL_MACHINE_DISK ?= "${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE}"
# for virtualbox this needs to be monolithicSparse
# for virtualbox this needs to be streamOptimized
#VMDK_SUBFORMAT ?= "streamOptimized"
VMDK_SUBFORMAT ?= "monolithicSparse"
def set_convert_options(d):
    format = d.getVar("VIRTUAL_MACHINE_IMAGE_TYPE")
    if format == "vmdk":
        return "-o subformat=%s" % d.getVar("VMDK_SUBFORMAT")
    else:
        return ""


CONVERSION_OPTIONS = "${@set_convert_options(d)}"

do_convert_wic() {
    rm -f '${DEPLOY_DIR_IMAGE}/${VIRTUAL_MACHINE_IMAGE_FILE}'
    image_do_mounts
    bbnote "Creating ${VIRTUAL_MACHINE_IMAGE_FILE} from ${WIC_IMAGE_FILE}"
    sudo -E  chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
    /usr/bin/qemu-img convert -f raw -O ${VIRTUAL_MACHINE_IMAGE_TYPE} ${CONVERSION_OPTIONS} \
    '${PP_DEPLOY}/${SOURCE_IMAGE_FILE}' '${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE}'
}

addtask convert_wic before do_build after do_wic_image do_copy_boot_files do_install_imager_deps do_transform_template

# Generate random MAC addresses just as VirtualBox does, the format is
# their assigned prefix for the first 3 bytes followed by 3 random bytes.
VBOX_MAC_PREFIX = "080027"
macgen() {
    hexdump -n3 -e "\"${VBOX_MAC_PREFIX}%06X\n\"" /dev/urandom
}
get_disksize() {
    image_do_mounts
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
    qemu-img info -f vmdk "${VIRTUAL_MACHINE_DISK}" | gawk 'match($0, /^virtual size:.*\(([0-9]+) bytes\)/, a) {print a[1]}'
}

do_create_ova() {
    if [ ! ${VIRTUAL_MACHINE_IMAGE_TYPE} = "vmdk" ]; then
        exit 0
    fi
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.ova'
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.ovf'
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.mf'
  
    export PRIMARY_MAC=$(macgen)
    export SECONDARY_MAC=$(macgen)
    export DISK_NAME=$(basename -s .vmdk ${VIRTUAL_MACHINE_DISK})
    export DISK_SIZE_BYTES=$(get_disksize)
    export LAST_CHANGE=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
    export OVA_FIRMWARE_VIRTUALBOX=$(echo ${OVA_FIRMWARE} | tr '[a-z]' '[A-Z]')
    image_do_mounts
    sudo -Es chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} <<'EOSUDO'
  export DISK_UUID=$(uuidgen)
  export VM_UUID=$(uuidgen)
   # create ovf
 cat > "${PP_DEPLOY}/${OVA_NAME}.ovf" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Envelope ovf:version="1.0" xml:lang="en-US" xmlns="http://schemas.dmtf.org/ovf/envelope/1" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData" xmlns:vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:vbox="http://www.virtualbox.org/ovf/machine">
  <References>
    <File ovf:href="${VIRTUAL_MACHINE_IMAGE_FILE}" ovf:id="file1"/>
  </References>
  <DiskSection>
    <Info>List of the virtual disks used in the package</Info>
    <Disk ovf:capacity="${DISK_SIZE_BYTES}" ovf:capacityAllocationUnits="byte" ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#${VMDK_SUBFORMAT}" vbox:uuid="${DISK_UUID}"/>
  </DiskSection>
  <NetworkSection>
    <Info>Logical networks used in the package</Info>
    <Network ovf:name="NAT">
      <Description>Logical network used by this appliance.</Description>
    </Network>
  </NetworkSection>
  <VirtualSystem ovf:id="${OVA_NAME}">
    <Info>A virtual machine</Info>
    <OperatingSystemSection ovf:id="100">
      <Info>The kind of installed guest operating system</Info>
      <Description>Debian_64</Description>
      <vbox:OSType ovf:required="false">Debian_64</vbox:OSType>
    </OperatingSystemSection>
    <VirtualHardwareSection>
      <Info>Virtual hardware requirements for a virtual machine</Info>
      <System>
        <vssd:ElementName>Virtual Hardware Family</vssd:ElementName>
        <vssd:InstanceID>0</vssd:InstanceID>
        <vssd:VirtualSystemIdentifier>${OVA_NAME}</vssd:VirtualSystemIdentifier>
        <vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>
      </System>
      <Item>
        <rasd:AllocationUnits>hertz * 10^6</rasd:AllocationUnits>
        <rasd:Caption>${OVA_NUMBER_OF_CPU} virtual CPU</rasd:Caption>
        <rasd:Description>Number of virtual CPUs</rasd:Description>
        <rasd:ElementName>${OVA_NUMBER_OF_CPU} virtual CPU</rasd:ElementName>
        <rasd:InstanceID>1</rasd:InstanceID>
        <rasd:ResourceType>3</rasd:ResourceType>
        <rasd:VirtualQuantity>${OVA_NUMBER_OF_CPU}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:AllocationUnits>MegaBytes</rasd:AllocationUnits>
        <rasd:Caption>${OVA_MEMORY} MB of memory</rasd:Caption>
        <rasd:Description>Memory Size</rasd:Description>
        <rasd:ElementName>${OVA_MEMORY} MB of memory</rasd:ElementName>
        <rasd:InstanceID>2</rasd:InstanceID>
        <rasd:ResourceType>4</rasd:ResourceType>
        <rasd:VirtualQuantity>${OVA_MEMORY}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:Caption>ideController0</rasd:Caption>
        <rasd:Description>IDE Controller</rasd:Description>
        <rasd:ElementName>ideController0</rasd:ElementName>
        <rasd:InstanceID>3</rasd:InstanceID>
        <rasd:ResourceSubType>PIIX4</rasd:ResourceSubType>
        <rasd:ResourceType>5</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:Address>1</rasd:Address>
        <rasd:Caption>ideController1</rasd:Caption>
        <rasd:Description>IDE Controller</rasd:Description>
        <rasd:ElementName>ideController1</rasd:ElementName>
        <rasd:InstanceID>4</rasd:InstanceID>
        <rasd:ResourceSubType>PIIX4</rasd:ResourceSubType>
        <rasd:ResourceType>5</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AutomaticAllocation>true</rasd:AutomaticAllocation>
        <rasd:Caption>Ethernet adapter on 'NAT'</rasd:Caption>
        <rasd:Connection>NAT</rasd:Connection>
        <rasd:ElementName>Ethernet adapter on 'NAT'</rasd:ElementName>
        <rasd:InstanceID>5</rasd:InstanceID>
        <rasd:ResourceSubType>E1000</rasd:ResourceSubType>
        <rasd:ResourceType>10</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:Caption>disk1</rasd:Caption>
        <rasd:Description>Disk Image</rasd:Description>
        <rasd:ElementName>disk1</rasd:ElementName>
        <rasd:HostResource>/disk/vmdisk1</rasd:HostResource>
        <rasd:InstanceID>6</rasd:InstanceID>
        <rasd:Parent>3</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
      </Item>
      <vmw:Config ovf:required="false" vmw:key="firmware" vmw:value="${OVA_FIRMWARE}"/>
      <vmw:Config ovf:required="false" vmw:key="tools.syncTimeWithHost" vmw:value="false"/>
      <vmw:Config ovf:required="false" vmw:key="tools.afterPowerOn" vmw:value="true"/>
      <vmw:Config ovf:required="false" vmw:key="tools.afterResume" vmw:value="true"/>
      <vmw:Config ovf:required="false" vmw:key="tools.beforeGuestShutdown" vmw:value="true"/>
      <vmw:Config ovf:required="false" vmw:key="tools.beforeGuestStandby" vmw:value="true"/>
      <vmw:ExtraConfig ovf:required="false" vmw:key="virtualHW.productCompatibility" vmw:value="hosted"/>
      </VirtualHardwareSection>
    <vbox:Machine ovf:required="false" version="1.12-linux" uuid="${VM_UUID}" name="${OVA_NAME}" OSType="Debian_64" snapshotFolder="Snapshots" lastStateChange="${LAST_CHANGE}">
      <ovf:Info>Complete VirtualBox machine configuration in VirtualBox format</ovf:Info>
      <Hardware version="2">
        <CPU count="${OVA_NUMBER_OF_CPU}" hotplug="false">
          <HardwareVirtEx enabled="true" exclusive="true"/>
          <HardwareVirtExNestedPaging enabled="true"/>
          <HardwareVirtExVPID enabled="true"/>
          <PAE enabled="true"/>
          <HardwareVirtExLargePages enabled="false"/>
          <HardwareVirtForce enabled="false"/>
        </CPU>
        <Memory RAMSize="${OVA_MEMORY}" PageFusion="false"/>
        <Firmware type="${OVA_FIRMWARE_VIRTUALBOX}"/>
        <HID Pointing="PS2Mouse" Keyboard="PS2Keyboard"/>
        <HPET enabled="false"/>
        <Chipset type="PIIX3"/>
        <Boot>
          <Order position="1" device="HardDisk"/>
          <Order position="2" device="None"/>
          <Order position="3" device="None"/>
          <Order position="4" device="None"/>
        </Boot>
        <Display VRAMSize="${OVA_VRAM}" monitorCount="1" accelerate3D="${OVA_3D_ACCEL}" accelerate2DVideo="false"/>
        <VideoRecording enabled="false" file="Test.webm" horzRes="640" vertRes="480"/>
        <RemoteDisplay enabled="false" authType="Null"/>
        <BIOS>
          <ACPI enabled="${OVA_ACPI}"/>
          <IOAPIC enabled="${OVA_ACPI}"/>
          <Logo fadeIn="true" fadeOut="true" displayTime="0"/>
          <BootMenu mode="MessageAndMenu"/>
          <TimeOffset value="0"/>
          <PXEDebug enabled="false"/>
        </BIOS>
        <USBController enabled="false" enabledEhci="false"/>
        <Network>
          <Adapter slot="0" enabled="true" MACAddress="${PRIMARY_MAC}" cable="true" speed="0" type="virtio">
            <DisabledModes/>
            <NAT>
              <DNS pass-domain="true" use-proxy="false" use-host-resolver="false"/>
              <Alias logging="false" proxy-only="false" use-same-ports="false"/>
            </NAT>
          </Adapter>
       </Network>
        <UART>
          <Port slot="0" enabled="false" IOBase="0x3f8" IRQ="4" hostMode="Disconnected"/>
          <Port slot="1" enabled="false" IOBase="0x2f8" IRQ="3" hostMode="Disconnected"/>
        </UART>
        <LPT>
          <Port slot="0" enabled="false" IOBase="0x378" IRQ="7"/>
          <Port slot="1" enabled="false" IOBase="0x378" IRQ="7"/>
        </LPT>
        <AudioAdapter controller="AC97" driver="Pulse" enabled="false"/>
        <RTC localOrUTC="local"/>
        <SharedFolders/>
        <Clipboard mode="Disabled"/>
        <DragAndDrop mode="Disabled"/>
        <IO>
          <IoCache enabled="true" size="5"/>
          <BandwidthGroups/>
        </IO>
        <HostPci>
          <Devices/>
        </HostPci>
        <EmulatedUSB>
          <CardReader enabled="false"/>
        </EmulatedUSB>
        <Guest memoryBalloonSize="0"/>
        <GuestProperties/>
      </Hardware>
      <StorageControllers>
        <StorageController name="IDE Controller" type="PIIX4" PortCount="2" useHostIOCache="true" Bootable="true">
          <AttachedDevice type="HardDisk" port="0" device="0">
            <Image uuid="{${DISK_UUID}}"/>
          </AttachedDevice>
        </StorageController>
      </StorageControllers>
    </vbox:Machine>
  </VirtualSystem>
</Envelope>
EOF
tar -H ustar -cvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${OVA_NAME}.ovf
tar -H ustar -uvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${VIRTUAL_MACHINE_IMAGE_FILE}

# virtual box needs here a manifest file vmware does not want to accept the format
if [ "${VMDK_SUBFORMAT}" = "monolithicSparse" ]; then
  echo "SHA${OVA_SHA_ALG}(${VIRTUAL_MACHINE_IMAGE_FILE})= $(sha${OVA_SHA_ALG}sum ${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE} | cut -d' ' -f1)" >> ${PP_DEPLOY}/${OVA_NAME}.mf
  echo "SHA${OVA_SHA_ALG}(${OVA_NAME}.ovf)= $(sha${OVA_SHA_ALG}sum ${PP_DEPLOY}/${OVA_NAME}.ovf | cut -d' ' -f1)" >> ${PP_DEPLOY}/${OVA_NAME}.mf
  tar -H ustar -uvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${OVA_NAME}.mf
fi
EOSUDO
}

addtask do_create_ova after do_convert_wic before do_deploy

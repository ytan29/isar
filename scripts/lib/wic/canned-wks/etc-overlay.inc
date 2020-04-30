# add a overlay partition to the image

# overlay partition
part --source etc-overlay --ondisk sda --size 100M --extra-space 128M --overhead-factor 1 --label etcovl --align 1024 --fstype=ext4

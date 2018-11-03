#!/bin/bash

##################################################
# Shell script to install raspberry pi
# image created using the tools at
# https://github.com/michaelfranzl/rpi23-gen-image
##################################################
runcommand()
{
    echo -e "\t$*";
    $TEST $*;
}

printUsage()
{
  cat <<.EOM
Usage: $0 [options] imageName
      Install the image specified.  The <imagename> must be one of the
      directories in the \"images\" directory.

Options:
   --test
      Print the commands that will be executed without executing
      them.

The script uses the following environment variables to customize the installation:
BOOT_DEVICE the name of the device for the boot partition as seen by the target system. Default: /dev/mmcblk0p1
ROOT_DEVICE the name of the device for the root filesystem as seen by the target system.  Default: /dev/mmcblk0p2
HOST_BOOT_DEV the name of th device for the boot partition as seen by the host PC. Default: /dev/mmcblk0p1
HOST_ROOT_DEV the name of th device for the root filesystem as seen by the host PC. Default: /dev/mmcblk0p2

For SD cards, the host and the target device names will most likely be the same.  When installing on USB storage,
the USB drive may have a different location, e.g. it may be /dev/sda on the target but /dev/sdb on the host PC.
.EOM
  exit 2
}

# Are we running as root?
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: this script must be executed with root privileges!"
  exit 1
fi

if [ "$#" -eq 0 ] ; then
	printUsage
fi

# Set the default values
TEST=""
HOSTNAME=""
while [ "$#" -gt 0 ] ;
do
    case "$1" in
	--test)   TEST="echo";;
  --host)   HOSTNAME=$2
            shift;;
	-?)			  printUsage;;
	--help)		printUsage;;
	*)        IMAGE=$1;;
    esac
    shift
done

BOOT_DEVICE=${BOOT_DEVICE:="/dev/mmcblk0p1"}
ROOT_DEVICE=${ROOT_DEVICE:="/dev/mmcblk0p2"}
HOST_BOOT_DEV=${HOST_BOOT_DEV:="/dev/mmcblk0p1"}
HOST_ROOT_DEV=${HOST_ROOT_DEV:="/dev/mmcblk0p2"}

if [ ! -d ./images/${IMAGE}/build/chroot ] ; then
    echo -e "Cannot find image directory: \"./images/${IMAGE}/build/chroot\""
    exit 2
fi

echo -n -e "Install \"${IMAGE}\" on ${HOST_BOOT_DEV} and ${HOST_ROOT_DEV}? [Y/n]"
read resp
#echo "Response is \"$resp\""
if [[ $resp == "" || $resp == [yY]* ]] ; then
    # now let's get to work!  Assumes that the partitions are already set up.
    runcommand umount ${HOST_BOOT_DEV}
    runcommand umount ${HOST_ROOT_DEV}
    runcommand mkfs.vfat -n "BOOT" ${HOST_BOOT_DEV}
    runcommand mkfs.ext4 -L "rootfs" ${HOST_ROOT_DEV}
    if [ -d /mnt/raspcard ] ; then
       runcommand mkdir -p /mnt/raspcard
    fi
    runcommand mount ${HOST_ROOT_DEV} /mnt/raspcard
    runcommand mkdir -p /mnt/raspcard/boot/firmware
    runcommand mount ${HOST_BOOT_DEV} /mnt/raspcard/boot/firmware
    runcommand rsync -a ./images/${IMAGE}/build/chroot/ /mnt/raspcard
    if [ ! -z "$HOSTNAME" ] ; then
      CURR_HOSTNAME=`cat ./images/${IMAGE}/build/chroot/etc/hostname`
      echo -e "\tUpdating hostname from \"${CURR_HOSTNAME}\" to \"$HOSTNAME\""
      runcommand sed -i s/${CURR_HOSTNAME}/$HOSTNAME/g /mnt/raspcard/etc/hostname
      runcommand sed -i s/${CURR_HOSTNAME}/$HOSTNAME/g /mnt/raspcard/etc/hosts
    fi
    runcommand umount ${HOST_BOOT_DEV}
    runcommand umount ${HOST_ROOT_DEV}
else
    exit 0
fi

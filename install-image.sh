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

# Are we running as root?
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: this script must be executed with root privileges!"
  exit 1
fi

#echo "There are $# arguments."

# Set the default values
IMAGE=stretch
DEVICE=/dev/mmcblk0p
TEST=""

while [ "$#" -gt 0 ] ;
do
    case "$1" in
	--image=*)  IMAGE=`echo $1 | sed -e s/--image=//`;;
	-i=*)       IMAGE=`echo $1 | sed -e s/-i=//`;;
	--device=*) DEVICE=`echo $1 | sed -e s/--device=//`;;
	-d=*)       DEVICE=`echo $1 | sed -e s/-d=//`;;
	--test)     TEST="echo";;
	*)          echo "Unrecognized option $1";;
    esac
    shift
done

if [ ! -d ./images/${IMAGE}/build/chroot ] ; then
    echo -e "Cannot find image directory: \"./images/${IMAGE}/build/chroot\""
    exit 2
fi

echo -n -e "Install \"${IMAGE}\" on ${DEVICE}1 and ${DEVICE}2? [Y/n]"
read resp
#echo "Response is \"$resp\""
if [[ $resp == "" || $resp == [yY]* ]] ; then
    # now let's get to work!  Assumes that the partitions are already set up.
    runcommand umount ${DEVICE}1
    runcommand umount ${DEVICE}2
    runcommand mkfs.vfat ${DEVICE}1
    runcommand mkfs.ext4 ${DEVICE}2
    if [ -d /mnt/raspcard ] ; then
       runcommand mkdir -p /mnt/raspcard
    fi
    runcommand mount ${DEVICE}2 /mnt/raspcard
    runcommand mkdir -p /mnt/raspcard/boot/firmware
    runcommand mount ${DEVICE}1 /mnt/raspcard/boot/firmware
    runcommand rsync -a ./images/${IMAGE}/build/chroot/ /mnt/raspcard
    runcommand umount ${DEVICE}1
    runcommand umount ${DEVICE}2
else
    exit 0
fi

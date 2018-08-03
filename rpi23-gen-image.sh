#!/bin/sh

########################################################################
# rpi23-gen-image.sh					       2015-2016
#
# Advanced Debian "jessie" and "stretch"  bootstrap script for RPi2/3
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2015 Jan Wagner <mail@jwagner.eu>
#
# Big thanks for patches and enhancements by 10+ github contributors!
########################################################################

# Are we running as root?
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: this script must be executed with root privileges!"
  exit 1
fi

# Check if ./functions.sh script exists
if [ ! -r "./functions.sh" ] ; then
  echo "error: './functions.sh' required script not found!"
  exit 1
fi

# Load utility functions
. ./functions.sh

# Introduce settings
set -e
echo -n -e "\n#\n# RPi2/3 Bootstrap Settings\n#\n"
set -x

# Raspberry Pi model configuration
RPI_MODEL=${RPI_MODEL:=2}

# Debian release
DEBIAN_RELEASE=${DEBIAN_RELEASE:=stretch}

# URLs
FIRMWARE_URL=${FIRMWARE_URL:=https://github.com/raspberrypi/firmware/raw/master/boot}
WLAN_FIRMWARE_URL=${WLAN_FIRMWARE_URL:=https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm}

# Build directories
BASEDIR="$(pwd)/images/${DEBIAN_RELEASE}"
BUILDDIR="${BASEDIR}/build"

# Chroot directories
R="${BUILDDIR}/chroot"
ETC_DIR="${R}/etc"
LIB_DIR="${R}/lib"
BOOT_DIR="${R}/boot/firmware"
KERNEL_DIR="${R}/usr/src/linux"
WLAN_FIRMWARE_DIR="${R}/lib/firmware/brcm"

# General settings
HOSTNAME=${HOSTNAME:=rpi${RPI_MODEL}-${DEBIAN_RELEASE}}
PASSWORD=${PASSWORD:=raspberry}
ROOTPASSWORD=${ROOTPASSWORD:=$PASSWORD}
DEFLOCAL=${DEFLOCAL:="en_US.UTF-8"}
TIMEZONE=${TIMEZONE:="Europe/Berlin"}

# Keyboard settings
XKB_MODEL=${XKB_MODEL:=""}
XKB_LAYOUT=${XKB_LAYOUT:=""}
XKB_VARIANT=${XKB_VARIANT:=""}
XKB_OPTIONS=${XKB_OPTIONS:=""}

# Network settings (DHCP)
ENABLE_DHCP=${ENABLE_DHCP:=true}

# Network settings (static)
NET_ADDRESS=${NET_ADDRESS:=""}
NET_GATEWAY=${NET_GATEWAY:=""}
NET_DNS_1=${NET_DNS_1:=""}
NET_DNS_2=${NET_DNS_2:=""}
NET_DNS_DOMAINS=${NET_DNS_DOMAINS:=""}
NET_NTP_1=${NET_NTP_1:=""}
NET_NTP_2=${NET_NTP_2:=""}

# APT settings
APT_PROXY=${APT_PROXY:=""}
APT_SERVER=${APT_SERVER:="ftp.debian.org"}

# Feature settings
ENABLE_CONSOLE=${ENABLE_CONSOLE:=true}
ENABLE_IPV6=${ENABLE_IPV6:=true}
ENABLE_SSHD=${ENABLE_SSHD:=true}
ENABLE_NONFREE=${ENABLE_NONFREE:=false}
ENABLE_WIRELESS=${ENABLE_WIRELESS:=false}
ENABLE_SOUND=${ENABLE_SOUND:=false}
ENABLE_DBUS=${ENABLE_DBUS:=true}
ENABLE_RSYSLOG=${ENABLE_RSYSLOG:=true}
ENABLE_USER=${ENABLE_USER:=true}
USER_NAME=${USER_NAME:="pi"}
ENABLE_ROOT=${ENABLE_ROOT:=true}
ENABLE_ROOT_SSH=${ENABLE_ROOT_SSH:=true}

# Advanced settings
ENABLE_MINBASE=${ENABLE_MINBASE:=false}
ENABLE_REDUCE=${ENABLE_REDUCE:=false}
ENABLE_HARDNET=${ENABLE_HARDNET:=false}
ENABLE_IPTABLES=${ENABLE_IPTABLES:=false}

# Kernel installation settings
KERNEL_HEADERS=${KERNEL_HEADERS:=true}
KERNELSRC_DIR=${KERNELSRC_DIR:=""}
UBOOTSRC_DIR=${UBOOTSRC_DIR:=""}

# Reduce disk usage settings
REDUCE_APT=${REDUCE_APT:=true}
REDUCE_DOC=${REDUCE_DOC:=true}
REDUCE_MAN=${REDUCE_MAN:=true}
REDUCE_VIM=${REDUCE_VIM:=false}
REDUCE_BASH=${REDUCE_BASH:=false}
REDUCE_HWDB=${REDUCE_HWDB:=true}
REDUCE_SSHD=${REDUCE_SSHD:=true}
REDUCE_LOCALE=${REDUCE_LOCALE:=true}

# Chroot scripts directory
CHROOT_SCRIPTS=${CHROOT_SCRIPTS:=""}

# Packages required in the chroot build environment
APT_INCLUDES=${APT_INCLUDES:=""}
APT_INCLUDES="${APT_INCLUDES},apt-transport-https,apt-utils,ca-certificates,debian-archive-keyring,systemd"

# Packages required for bootstrapping  (host PC)
REQUIRED_PACKAGES="debootstrap debian-archive-keyring qemu-user-static binfmt-support dosfstools rsync bmap-tools whois git"
MISSING_PACKAGES=""


set +x


# Set Raspberry Pi model specific configuration
if [ "$RPI_MODEL" = 2 ] ; then
  DTB_FILE=bcm2836-rpi-2-b.dtb
  DEBIAN_RELEASE_ARCH=armhf
  KERNEL_ARCH=arm
  CROSS_COMPILE=arm-linux-gnueabihf-
  KERNEL_IMAGE_SOURCE=zImage
  KERNEL_IMAGE_TARGET=linuz.img
  QEMU_BINARY=/usr/bin/qemu-arm-static
  UBOOT_CONFIG=rpi_2_defconfig

elif [ "$RPI_MODEL" = 3 ] ; then
  DTB_FILE=broadcom/bcm2837-rpi-3-b.dtb
  DEBIAN_RELEASE_ARCH=arm64
  KERNEL_ARCH=arm64
  CROSS_COMPILE=aarch64-linux-gnu-
  KERNEL_IMAGE_SOURCE=Image.gz
  KERNEL_IMAGE_TARGET=linux.uImage
  QEMU_BINARY=/usr/bin/qemu-aarch64-static
  UBOOT_CONFIG=rpi_3_defconfig

else
  echo "error: Raspberry Pi model ${RPI_MODEL} is not supported!"
  exit 1
fi

# Check if the internal wireless interface is supported by the RPi model
if [ "$ENABLE_WIRELESS" = true ] && [ "$RPI_MODEL" != 3 ] ; then
  echo "error: The selected Raspberry Pi model has no internal wireless interface"
  exit 1
fi


# Fail early: Is kernel ready?
if [ ! -e "${KERNELSRC_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" ] ; then
  echo "error: cannot proceed: Linux kernel must be precompiled"
  exit 1
fi

# Fail early: Is u-boot ready?
if [ ! -e "${UBOOTSRC_DIR}/u-boot.bin" ] ; then
  echo "error: cannot proceed: U-Boot bootloader must be precompiled"
  exit 1
fi

# Fail early: Is firmware ready?
if [ ! -d "$RPI_FIRMWARE_DIR" ] ; then
  echo "error: Raspberry Pi firmware directory not specified or not found!"
  exit 1
fi


# Check if all required packages are installed on the build system
for package in $REQUIRED_PACKAGES ; do
  if [ "`dpkg-query -W -f='${Status}' $package`" != "install ok installed" ] ; then
    MISSING_PACKAGES="${MISSING_PACKAGES} $package"
  fi
done

# Ask if missing packages should be installed right now
if [ -n "$MISSING_PACKAGES" ] ; then
  echo "the following packages needed by this script are not installed:"
  echo "$MISSING_PACKAGES"

  echo -n "\ndo you want to install the missing packages right now? [y/n] "
  read confirm
  [ "$confirm" != "y" ] && exit 1
fi

# Make sure all required packages are installed
apt-get -qq -y install ${REQUIRED_PACKAGES}

# Check if ./bootstrap.d directory exists
if [ ! -d "./bootstrap.d/" ] ; then
  echo "error: './bootstrap.d' required directory not found!"
  exit 1
fi

# Check if ./files directory exists
if [ ! -d "./files/" ] ; then
  echo "error: './files' required directory not found!"
  exit 1
fi

# Check if specified CHROOT_SCRIPTS directory exists
if [ -n "$CHROOT_SCRIPTS" ] && [ ! -d "$CHROOT_SCRIPTS" ] ; then
   echo "error: ${CHROOT_SCRIPTS} specified directory not found (CHROOT_SCRIPTS)!"
   exit 1
fi

# Don't clobber an old build
if [ -e "$BUILDDIR" ] ; then
  echo "error: directory ${BUILDDIR} already exists, not proceeding"
  exit 1
fi


# Setup chroot directory
mkdir -p "${R}"

# Check if build directory has enough of free disk space >512MB
if [ "$(df --output=avail ${BUILDDIR} | sed "1d")" -le "524288" ] ; then
  echo "error: ${BUILDDIR} not enough space left to generate the output image!"
  exit 1
fi

set -x

# Call "cleanup" function on various signals and errors
trap cleanup 0 1 2 3 6

# Add required packages for the minbase installation
if [ "$ENABLE_MINBASE" = true ] ; then
  APT_INCLUDES="${APT_INCLUDES},vim-tiny,netbase,net-tools,ifupdown"
fi

# Add required locales packages
if [ "$DEFLOCAL" != "en_US.UTF-8" ] ; then
  APT_INCLUDES="${APT_INCLUDES},locales,keyboard-configuration,console-setup"
fi

# Add dbus package, recommended if using systemd
if [ "$ENABLE_DBUS" = true ] ; then
  APT_INCLUDES="${APT_INCLUDES},dbus"
fi

# Add iptables IPv4/IPv6 package
if [ "$ENABLE_IPTABLES" = true ] ; then
  APT_INCLUDES="${APT_INCLUDES},iptables"
fi

# Add openssh server package
if [ "$ENABLE_SSHD" = true ] ; then
  APT_INCLUDES="${APT_INCLUDES},openssh-server"
fi

# Add alsa-utils package
if [ "$ENABLE_SOUND" = true ] ; then
  APT_INCLUDES="${APT_INCLUDES},alsa-utils"
fi


# Replace selected packages with smaller clones
if [ "$ENABLE_REDUCE" = true ] ; then
  # Add levee package instead of vim-tiny
  if [ "$REDUCE_VIM" = true ] ; then
    APT_INCLUDES="$(echo ${APT_INCLUDES} | sed "s/vim-tiny/levee/")"
  fi

  # Add dropbear package instead of openssh-server
  if [ "$REDUCE_SSHD" = true ] ; then
    APT_INCLUDES="$(echo ${APT_INCLUDES} | sed "s/openssh-server/dropbear/")"
  fi
fi


# Execute bootstrap scripts
for SCRIPT in bootstrap.d/*.sh; do
  head -n 3 "$SCRIPT"
  . "$SCRIPT"
done

## Execute custom bootstrap scripts
if [ -d "custom.d" ] ; then
  for SCRIPT in custom.d/*.sh; do
    . "$SCRIPT"
  done
fi

# Execute custom scripts inside the chroot
if [ -n "$CHROOT_SCRIPTS" ] && [ -d "$CHROOT_SCRIPTS" ] ; then
  cp -r "${CHROOT_SCRIPTS}" "${R}/chroot_scripts"
  chroot_exec /bin/bash -x <<'EOF'
for SCRIPT in /chroot_scripts/* ; do
  if [ -f $SCRIPT -a -x $SCRIPT ] ; then
    $SCRIPT
  fi
done
EOF
  rm -rf "${R}/chroot_scripts"
fi

# Remove apt-utils
chroot_exec apt-get purge -qq -y --force-yes apt-utils

# Generate required machine-id
MACHINE_ID=$(dbus-uuidgen)
echo -n "${MACHINE_ID}" > "${R}/var/lib/dbus/machine-id"
echo -n "${MACHINE_ID}" > "${ETC_DIR}/machine-id"

# APT Cleanup
chroot_exec apt-get -y clean
chroot_exec apt-get -y autoclean
chroot_exec apt-get -y autoremove

# Unmount mounted filesystems
umount -l "${R}/proc"
umount -l "${R}/sys"

# Clean up directories
rm -rf "${R}/run/*"
rm -rf "${R}/tmp/*"

# Clean up files
rm -f "${ETC_DIR}/ssh/ssh_host_*"
rm -f "${ETC_DIR}/dropbear/dropbear_*"
rm -f "${ETC_DIR}/apt/sources.list.save"
rm -f "${ETC_DIR}/resolvconf/resolv.conf.d/original"
rm -f "${ETC_DIR}/*-"
rm -f "${ETC_DIR}/apt/apt.conf.d/10proxy"
rm -f "${ETC_DIR}/resolv.conf"
rm -f "${R}/root/.bash_history"
rm -f "${R}/var/lib/urandom/random-seed"
rm -f "${R}/initrd.img"
rm -f "${R}/vmlinuz"
rm -f "${R}${QEMU_BINARY}"

echo ""
echo "DONE!"
echo ""

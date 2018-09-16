#!/bin/bash

DEBIAN_RELEASE="stretch" \
				BUILD_SUBDIR="stretch-dev" \
	      USER_NAME="grady" \
	      PASSWORD="initpasswd" \
	      ROOTPASSWORD="Nanki@p00" \
	      TIMEZONE="America/New_York" \
	      APT_SERVER="ftp.debian.org" \
	      APT_INCLUDES="i2c-tools,rng-tools,net-tools,avahi-daemon,rsync,emacs,sudo,wpasupplicant,wireless-regdb,rpcbind,dns-root-data,crda,less,patch,make,git,procps,iproute2,iptables,iw,hostapd,dnsmasq,curl,zlib1g,zlib1g-dev" \
	      APT_PROXY="localhost:3142" \
	      UBOOTSRC_DIR="$(pwd)/../u-boot" \
	      KERNELSRC_DIR="$(pwd)/../linux" \
	      RPI_MODEL=3 \
	      HOSTNAME="lfserv" \
	      RPI_FIRMWARE_DIR="$(pwd)/../raspberry-firmware" \
	      ENABLE_NONFREE=true \
	      ENABLE_WIRELESS=true \
	      ENABLE_MINBASE=false \
	      ENABLE_IPTABLES=true \
	      ./rpi23-gen-image.sh

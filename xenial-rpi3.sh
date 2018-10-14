#!/bin/bash

DEBIAN_RELEASE="xenial" \
	      USER_NAME="pi" \
	      PASSWORD="raspberry" \
	      ROOTPASSWORD="Nanki@p00" \
	      TIMEZONE="America/New_York" \
				APT_PROXY="localhost:3142" \
	      APT_INCLUDES="apt-utils,net-tools,avahi-daemon,rsync,emacs,sudo,rpcbind,dns-root-data,crda,less,patch,make,git,procps,iproute2,iptables,iw,curl,zlib1g,zlib1g-dev" \
	      UBOOTSRC_DIR="$(pwd)/../u-boot" \
	      KERNELSRC_DIR="$(pwd)/../linux" \
	      RPI_MODEL=3 \
	      HOSTNAME="xenialpi" \
	      RPI_FIRMWARE_DIR="$(pwd)/../raspberry-firmware" \
	      ENABLE_NONFREE=true \
	      ENABLE_WIRELESS=true \
	      ENABLE_MINBASE=false \
	      ENABLE_IPTABLES=true \
	      ./rpi23-gen-image.sh

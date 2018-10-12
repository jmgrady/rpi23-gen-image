#
# Setup APT repositories
#

# Load utility functions
. ./functions.sh

# Install and setup APT proxy configuration
if [ -z "$APT_PROXY" ] ; then
  install_readonly files/apt/10proxy "${ETC_DIR}/apt/apt.conf.d/10proxy"
  sed -i "s/\"\"/\"${APT_PROXY}\"/" "${ETC_DIR}/apt/apt.conf.d/10proxy"
fi

if [ "$OS_VARIANT" = "debian" ] ; then
  install_readonly files/apt/sources.list "${ETC_DIR}/apt/sources.list"
elif [ "$OS_VARIANT" = "ubuntu-ports" ] ; then
  install_readonly files/apt/ubuntu-sources.list "${ETC_DIR}/apt/sources.list"
else
  echo -n -e "\n\nerror: no OS_VARIANT specified."
fi

# Use specified APT server and release
sed -i "s/\%APT_SERVER\%/${APT_SERVER}/" "${ETC_DIR}/apt/sources.list"
sed -i "s/ \%DEBIAN_RELEASE\%/ ${DEBIAN_RELEASE}/" "${ETC_DIR}/apt/sources.list"


# Allow the installation of non-free Debian packages
if [ "$ENABLE_NONFREE" = true ] ; then
  sed -i "s/ contrib/ contrib non-free/" "${ETC_DIR}/apt/sources.list"
fi

# Upgrade package index and update all installed packages and changed dependencies
chroot_exec apt-get -qq -y update
chroot_exec apt-get -qq -y -u dist-upgrade

if [ -d packages ] ; then
  for package in packages/*.deb ; do
    cp $package ${R}/tmp
    chroot_exec dpkg --unpack /tmp/$(basename $package)
  done
fi
chroot_exec apt-get -qq -y -f install

chroot_exec apt-get -qq -y check

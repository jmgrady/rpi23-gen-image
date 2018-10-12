#
# Debootstrap basic system
#

# Load utility functions
. ./functions.sh

VARIANT=""
COMPONENTS="main"

# Use non-free Debian packages if needed
if [ "$ENABLE_NONFREE" = true ] ; then
  COMPONENTS="main,non-free"
fi

# Use minbase bootstrap variant which only includes essential packages
if [ "$ENABLE_MINBASE" = true ] ; then
  VARIANT="--variant=minbase"
fi

# Base debootstrap (unpack only)
http_proxy=${APT_PROXY} debootstrap --keep-debootstrap-dir --arch="${DEBIAN_RELEASE_ARCH}" --foreign ${VARIANT} --components="${COMPONENTS}" --include="${APT_INCLUDES}" "${DEBIAN_RELEASE}" "${R}" "http://${APT_SERVER}/${OS_VARIANT}"

# Copy qemu emulator binary to chroot
install -m 755 -o root -g root "${QEMU_BINARY}" "${R}${QEMU_BINARY}"

# Copy debian-archive-keyring.pgp
mkdir -p "${R}/usr/share/keyrings"
install_readonly /usr/share/keyrings/${KEYRING}.gpg "${R}/usr/share/keyrings/${KEYRING}.gpg"

# Complete the bootstrapping process
chroot_exec /debootstrap/debootstrap --second-stage --keep-debootstrap-dir

# Mount required filesystems
mount -t proc none "${R}/proc"
mount -t sysfs none "${R}/sys"

# Mount pseudo terminal slave if supported by Debian release
if [ -d "${R}/dev/pts" ] ; then
  mount --bind /dev/pts "${R}/dev/pts"
fi

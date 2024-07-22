#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath "$(dirname "$0")")
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p "${OUTDIR}"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Kernel build steps
    
    # Patch - https://github.com/torvalds/linux/commit/e33a814e772cdc36436c8c188d8c42d019fda639
    sed -i '/YLTYPE yylloc;/d' scripts/dtc/dtc-lexer.l

    make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" mrproper
    make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" defconfig
    make -j4 ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" all
    # make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" modules
    make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" dtbs
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf "${OUTDIR}/rootfs"
fi

# Create necessary base directories
mkdir "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr/bin usr/lib usr/sbin var/log

cd "${OUTDIR}"

if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# Make and install busybox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd "${OUTDIR}/rootfs"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

echo "Copying library dependencies"
# Add library dependencies to rootfs
SYSROOT=$(aarch64-none-linux-gnu-gcc --print-sysroot)

cd "${SYSROOT}/lib64"

cp -av ld-2.33.so libm-2.33.so libm.so.6 libresolv-2.33.so libresolv.so.2 libc-2.33.so libc.so.6 "${OUTDIR}/rootfs/lib64"
cp -av ../lib/ld-linux-aarch64.so.1 "${OUTDIR}/rootfs/lib"

# Make device nodes
cd "${OUTDIR}/rootfs"
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1


# Clean and build the writer utility
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE} all

# Copy the finder related scripts and executables to the /home directory on the target rootfs
cp -v writer finder.sh finder-test.sh autorun-qemu.sh "${OUTDIR}/rootfs/home"
cp -Hrv conf "${OUTDIR}/rootfs/home" 

# Chown the root directory
cd "${OUTDIR}"
sudo chown -R root:root "${OUTDIR}/rootfs"

# Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd "${OUTDIR}"
gzip -f initramfs.cpio

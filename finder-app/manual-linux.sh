#!/bin/bash
# Script outline to install and build kernel.


set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    cd "$OUTDIR/linux-stable"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then                
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

mkdir -p rootfs
cd rootfs
mkdir -p bin dev etc hoe lib lib64 proc sbin sys tmp usr var home
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd "$OUTDIR"
cp -r bin ${OUTDIR}/rootfs
cp -r sbin ${OUTDIR}/rootfs
cp -r usr ${OUTDIR}/rootfs
cp linuxrc ${OUTDIR}/rootfs

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
find / -type f -name "lib/ld-linux-aarch64.so.1" -exec echo {} \;
find / -type f -name "libm.so.6" -exec echo {} \;
find / -type f -name "libresolv.so.2" -exec echo {} \;
find / -type f -name "libc.so.6" -exec echo {} \;

#find /home/rory/ARM_ToolChain/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -type f -name "ld-linux-aarch64.so.1" -exec echo {} \;
#find /home/rory/ARM_ToolChain/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -type f -name "libm.so.6" -exec echo {} \;
#find /home/rory/ARM_ToolChain/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -type f -name "libresolv.so.2" -exec echo {} \;
#find /home/rory/ARM_ToolChain/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -type f -name "libc.so.6" -exec echo {} \;

find / -type f -name "ld-linux-aarch64.so.1" -exec cp {} ${OUTDIR}/rootfs/lib/ \;
find / -type f -name "libm.so.6" -exec cp {} ${OUTDIR}/rootfs/lib64/ \;
find / -type f -name "libresolv.so.2" -exec cp {} ${OUTDIR}/rootfs/lib64/ \;
find / -type f -name "libc.so.6" -exec cp {} ${OUTDIR}/rootfs/lib64/ \;

# TODO: Make device nodes
cd "$OUTDIR/rootfs"
sudo mknod -m 0666 dev/null c 1 3
sudo mknod -m 0666 dev/console c 5 1

# TODO: Clean and build the writer utility

sudo chmod ugo+rwx ${SCRIPT_DIR}
cd "$SCRIPT_DIR"
pwd
make CROSS_COMPILE=aarch64-none-linux-gnu- clean
make CROSS_COMPILE=aarch64-none-linux-gnu- build

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cp writer.c writer.o finder.sh finder-test.sh writer.sh writer ${OUTDIR}/rootfs/home
mkdir ${OUTDIR}/rootfs/home/conf
cp -r conf/username.txt ${OUTDIR}/rootfs/home/conf
cp -r conf/assignment.txt ${OUTDIR}/rootfs/home/conf
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
sudo chown -R :users ${OUTDIR}/rootfs
# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

#sleep 600m

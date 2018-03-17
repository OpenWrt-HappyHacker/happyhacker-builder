#!/bin/sh
#
# OpenWrt Happy Hacker edition
# ============================
#
# Flashing script for ZSUN devices.
#
# This script is meant to be run from your PC.
#

# Set the error mode to stop on any error.
set -e
##set -x

# Some constants we will be using in this script.
FILENAME_KERNEL=openwrt-ar71xx-generic-zsun-sdreader-kernel.bin
FILENAME_ROOTFS=openwrt-ar71xx-generic-zsun-sdreader-rootfs-squashfs.bin
REGEXP_ZSUN_BSSID="zsun-sd[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]"

# Make sure we are already associated to the ZSUN Wi-Fi network.
BSSID=$(iwgetid | grep -o "${REGEXP_ZSUN_BSSID}")
if [ -z "${BSSID}" ]
then
    >&2 echo "ERROR: you must connect to the ZSUN Wi-Fi access point before running this command."
    exit 1
fi

# Let the user know we identified the device.
echo "Detected ZSUN device: ${BSSID}"

# Verify the image files to be flashed exist and can be read.
BIN_KERNEL=./firmware/$FILENAME_KERNEL
BIN_ROOTFS=./firmware/$FILENAME_ROOTFS
if ! [ -r $BIN_KERNEL ]
then
    >&2 echo "ERROR: cannot read file: ${BIN_KERNEL}"
    exit 1
fi
if ! [ -r $BIN_ROOTFS ]
then
    >&2 echo "ERROR: cannot read file: ${BIN_ROOTFS}"
    exit 1
fi

# Verify the images to be flashed are not corrupt.
HASH_KERNEL=$(sha256sum $BIN_KERNEL | cut -d ' ' -f 1)
HASH_ROOTFS=$(sha256sum $BIN_ROOTFS | cut -d ' ' -f 1)
HASH_KERNEL_MUST_BE=$(cat ./firmware/sha256sums | grep $FILENAME_KERNEL | cut -d = -f 2 | xargs)
HASH_ROOTFS_MUST_BE=$(cat ./firmware/sha256sums | grep $FILENAME_ROOTFS | cut -d = -f 2 | xargs)
if [ "${HASH_KERNEL_MUST_BE}" != "${HASH_KERNEL}" ]
then
    >&2 echo "ERROR: file is corrupt: ${BIN_KERNEL}"
    exit 1
fi
if [ "${HASH_ROOTFS_MUST_BE}" != "${HASH_ROOTFS}" ]
then
    >&2 echo "ERROR: file is corrupt: ${BIN_ROOTFS}"
    exit 1
fi

# TODO
# WORK IN PROGRESS

#!/bin/sh
#
# OpenWrt HappyHacker upgrade script
#
# This script assumes the following things:
# * The device you're flashing is a ZSUN with our edition of OpenWrt inside.
# * You are (obviously) running it inside the device and as root.
# * The firmware files can be found at /mnt/sda1 (the default mount point for the SD card).
# * The rootfs file must be present. The kernel one is optional.
#
# The script will do its best to detect errors and warn you about them.
# But given the nature of what we're doing, if something goes wrong, there is little to do.
# It may work on a standard OpenWrt build, but we haven't tested this - YMMV.
#

# Make sure the user isn't trying to run this on their PC.
# (Seriously. You would be surprised.)
if ! [ "$(uname -m)" = "mips" ]
then
    >&2 echo "This script must be run from the device, not your PC."
    exit 1
fi

# Make sure we can access the new firmware images.
# If the kernel image is present, the rootfs must be too.
# The rootfs can be on its own if you don't need to upgrade the kernel.
if ! [ -e /mnt/sda1/openwrt-ar71xx-generic-zsun-sdreader-rootfs-squashfs.bin ]
then
    >&2 echo "Cannot find replacement rootfs, aborting."
fi
if ! [ -r /mnt/sda1/openwrt-ar71xx-generic-zsun-sdreader-rootfs-squashfs.bin ]
then
    >&2 echo "Replacement rootfs is not readable, aborting."
fi
if [ -e /mnt/sda1/openwrt-ar71xx-generic-zsun-sdreader-kernel.bin ] && ! [ -r /mnt/sda1/openwrt-ar71xx-generic-zsun-sdreader-kernel.bin ]
then
    >&2 echo "Replacement kernel is not readable, aborting."
fi

# Copy the reboot binary to /tmp (see the end of this script).
# We don't care if this fails, so no error checking here.
cp /sbin/reboot /tmp/
chmod +x /tmp/reboot

# Determine where the MTD partitions to reflash are located.
# We cannot use the "mtd" command, because it expects a specific format we don't have.
MTD_KERNEL=$(cat /proc/mtd | grep \"kernel\" | cut -d ':' -f 1 | grep mtd.)
if [ -z "MTD_KERNEL" ] || ! [ $(echo "${MTD_KERNEL}" | wc -w) == 1 ]
then
    >&2 echo "Cannot find kernel MTD, aborting."
    exit 1
fi
MTD_ROOTFS=$(cat /proc/mtd | grep \"rootfs\" | cut -d ':' -f 1 | grep mtd.)
if [ -z "MTD_ROOTFS" ] || ! [ $(echo "${MTD_ROOTFS}" | wc -w) == 1 ]
then
    >&2 echo "Cannot find rootfs MTD, aborting."
    exit 1
fi

# Make the LED blink, so the user knows something hardcore is going on. }:)
# Again, we don't care if this fails, so no error checking either.
echo timer > /sys/class/leds/zsunsdreader\:green\:system/trigger 2> /dev/null

# Remount the rootfs as readonly to prevent corrupting it while flashing.
mount -o remount,ro /
if ! [ $? == 0 ]
then
    >&2 echo "Cannot remount rootfs as read-only, aborting."
    exit 1
fi

# Back up the partitions we are about to flash.
echo "Backing up old firmware..."
dd if=/dev/$MTD_KERNEL of=/mnt/sda1/backup_$MTD_KERNEL.bin bs=65536
dd if=/dev/$MTD_ROOTFS of=/mnt/sda1/backup_$MTD_ROOTFS.bin bs=65536

# Flash the kernel first.
echo "Flashing new kernel image into the device..."
echo dd if=/mnt/sda1/openwrt-ar71xx-generic-zsun-sdreader-kernel.bin of=/dev/$MTD_KERNEL bs=65536
if ! [ $? == 0 ]
then
    >&2 echo "WARNING: An error occurred while flashing the new kernel!"
    >&2 echo "         You may experience problems on this device!"
    echo "Restoring old kernel image..."
    echo dd if=/mnt/sda1/backup_$MTD_KERNEL.bin of=/dev/$MTD_KERNEL bs=65536
    cho "Rebooting in 5 seconds..."
    leep 5
    /tmp/reboot now
    exit 1    # just in case reboot fails...
fi

# Flash the rootfs and reboot.
echo "Flashing new rootfs image into the device..."
echo dd if=/mnt/sda1/openwrt-ar71xx-generic-zsun-sdreader-rootfs-squashfs.bin of=/dev/$MTD_ROOTFS bs=65536
if ! [ $? == 0 ]
then
    >&2 echo "WARNING: An error occurred while flashing the new rootfs!"
    >&2 echo "         You may experience problems on this device!"
    echo "Restoring old kernel image..."
    echo dd if=/mnt/sda1/backup_$MTD_KERNEL.bin of=/dev/$MTD_KERNEL bs=65536
    echo "Restoring old rootfs image..."
    echo dd if=/mnt/sda1/backup_$MTD_ROOTFS.bin of=/dev/$MTD_ROOTFS bs=65536
    cho "Rebooting in 5 seconds..."
    leep 5
    /tmp/reboot now
    exit 1    # just in case reboot fails...
fi

# Reboot immediately.
/tmp/reboot now
exit 1    # just in case reboot fails...

#!/bin/bash

# This script destroys all changes made by lxd_up.sh.

# If the container is running, stop it.
# It is important to do this before anything else, to avoid data corruption.
if [[ $(lxc info "${LXD_CONTAINER_NAME}" | grep ^Status:\ .*\$ | sed "s/^Status: \(.*\)\$/\\1/" | grep -F Stopped | wc -c) = 0 ]]
then
    echo "Stopping the container..."
    lxc stop "${LXD_CONTAINER_NAME}"
fi

# If the shared folder exists, unmount it.
# It is VERY IMPORTANT to do this BEFORE destroying the container,
# otherwise we would be deleting the host files as well.
if [[ $(mount | grep ^bindfs | grep -F "bindfs on /var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE" | wc -c) = 0 ]] # Ubuntu
then
    LXD_CONTAINER_REAL_PATH=$(realpath "/var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE")
    if [[ $(mount | grep -F "${LXD_CONTAINER_REAL_PATH} type fuse" | wc -c) = 0 ]]                                              # Fedora
    then
        echo "Shared folder already unmounted, nothing to do."
    else
        echo "Unmounting shared folder... (this may trigger a sudo prompt)"
        sudo umount -f "${LXD_CONTAINER_REAL_PATH}"
    fi
else
    echo "Unmounting shared folder... (this may trigger a sudo prompt)"
    sudo umount -f "/var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE"
fi

# If the container exists, stop and destroy it.
# It is VERY IMPORTANT to do this AFTER unmounting the shared folder,
# otherwise we would be deleting the host files as well.
if [[ $(lxc info "${LXD_CONTAINER_NAME}" 2> /dev/null | wc -c) = 0 ]]
then
    echo "Container was already deleted, nothing to do."
else
    echo "Deleting container..."
    lxc delete --force "${LXD_CONTAINER_NAME}"
fi

# If the network exists, delete it.
# This assumes no other container is attached to it.
if [[ $(lxc network show "${LXD_NETWORK_NAME}" 2> /dev/null | wc -c) = 0 ]]
then
    echo "Network was already deleted, nothing to do."
else
    echo "Deleting network..."
    lxc network delete "${LXD_NETWORK_NAME}"
fi


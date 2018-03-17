#!/bin/bash

# This script configures an LXD container to be used as a sandbox in which to
# build OpenWrt without having to make changes to the host system.

# XXX TODO:
# On Fedora we may need to disable SELinux to run LXD:
# $ setenforce permissive
# $ systemctl start lxd

# If the container does not exist, create it.
if [[ $(lxc info "${LXD_CONTAINER_NAME}" 2> /dev/null | wc -c) = 0 ]]
then
    echo "Creating the container..."
    lxc launch "${LXD_REMOTE_IMAGE}" "${LXD_CONTAINER_NAME}"
fi

# If the network does not exist, create it.
if [[ $(lxc network show "${LXD_NETWORK_NAME}" 2> /dev/null | wc -c) = 0 ]]
then
    echo "Creating the network..."
    lxc network create "${LXD_NETWORK_NAME}"
fi

# If the network was not attached to our container, attach it.
if [[ $(lxc network show "${LXD_NETWORK_NAME}" | grep usedby | wc -c) = 0 ]]
then
    # Ubuntu
    KEYWORD=used_by
else
    # Fedora
    KEYWORD=usedby
fi
if [[ $(lxc network show "${LXD_NETWORK_NAME}" | sed "0,/${KEYWORD}/d" | rev | cut -d "/" -f1 | rev | grep -Fx "${LXD_CONTAINER_NAME}" | wc -c) = 0 ]]
then
    echo "Attaching the network to the container..."
    lxc network attach "${LXD_NETWORK_NAME}" "${LXD_CONTAINER_NAME}"
fi

# If the container does not have its shared folder mapped, map it.
if [[ $(mount | grep ^bindfs | grep -F "bindfs on /var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE" | wc -c) = 0 ]] # Ubuntu
then
    LXD_CONTAINER_REAL_PATH=$(realpath "/var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE")
    if [[ $(mount | grep -F "${LXD_CONTAINER_REAL_PATH} type fuse" | wc -c) = 0 ]]                                              # Fedora
    then
        echo "Creating shared folder... (this may trigger a sudo prompt)"
        sudo script/host/lxd_mount_shared_folder.sh
    fi
fi

# If the container was not running, start it.
if [[ $(lxc info "${LXD_CONTAINER_NAME}" | grep ^Status:\ .*\$ | sed "s/^Status: \(.*\)\$/\\1/" | grep -F Running | wc -c) = 0 ]]
then
    echo "Starting the container..."
    lxc start "${LXD_CONTAINER_NAME}"
fi

# If the container has not been provisioned, provision it.
if [[ $(lxc exec "${LXD_CONTAINER_NAME}" -- bash -c "if [ -e /.provisioned ] ; then echo 1; else echo 0; fi") = 0 ]]
then
    echo "Provisioning the container..."
    lxc exec "${LXD_CONTAINER_NAME}" bash /OUTSIDE/script/guest/prov-lxd.sh
fi


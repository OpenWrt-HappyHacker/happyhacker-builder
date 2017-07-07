#!/bin/bash

# This script configures an LXD container to be used as a sandbox in which to
# build OpenWrt without having to make changes to the host system.

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
if [[ $(lxc network show "${LXD_NETWORK_NAME}" | sed '0,/usedby/d' | rev | cut -d "/" -f1 | rev | grep -Fx "${LXD_CONTAINER_NAME}" | wc -c) = 0 ]]
then
    echo "Attaching the network to the container..."
    lxc network attach "${LXD_NETWORK_NAME}" "${LXD_CONTAINER_NAME}"
fi

# If the container does not have its shared folder mapped, map it.
if [[ $(mount | grep ^bindfs | grep -F "bindfs on /var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE" | wc -c) = 0 ]]
then
    echo "Creating shared folder... (this may trigger a sudo prompt)"

    # Get the current user and group names.
    CURRENT_USER=$(id -un)
    CURRENT_GROUP=$(id -gn)

    # Get the container's user and group names.
    # Note how we use the unprivileged user and group for this.
    CONTAINER_USER=$(ls -ld "/var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/home/${LXD_INSIDE_USER}" | cut -d " " -f 3)
    CONTAINER_GROUP=$(ls -ld "/var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/home/${LXD_INSIDE_USER}" | cut -d " " -f 4)

    # Get the directory to mount and the mount point.
    OUTSIDE_DIR_IN_HOST=$(realpath .)
    OUTSIDE_DIR_IN_GUEST="/var/lib/lxd/containers/${LXD_CONTAINER_NAME}/rootfs/OUTSIDE"

    # Ensure the mount point for the shared folder exists.
    if ! [ -d "${OUTSIDE_DIR_IN_GUEST}" ]
    then
        lxc exec "${LXD_CONTAINER_NAME}" -- bash -c "mkdir /OUTSIDE ; chown ${LXD_INSIDE_USER}:${LXD_INSIDE_GROUP} /OUTSIDE"
        if ! [ -d "${OUTSIDE_DIR_IN_GUEST}" ]
        then
            echo "Internal error :("    # should never fail, but...
            exit 1
        fi
    fi

    # Mount the shared folder.
    sudo -- bindfs -u ${CONTAINER_USER} -g ${CONTAINER_GROUP} \
            --create-for-user=${CURRENT_USER} --create-for-group=${CURRENT_GROUP} \
            --chown-deny --chgrp-deny --chmod-normal --realistic-permissions \
            "${OUTSIDE_DIR_IN_HOST}" "${OUTSIDE_DIR_IN_GUEST}"
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


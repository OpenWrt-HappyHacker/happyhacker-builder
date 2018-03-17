#!/bin/bash

# This script mounts a shared folder between the container and the host.
# Sadly, this feature is not yet implemented officially in LXD, so we
# have to do it ourselves using bindfs.

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Get the current user and group names.
# Since this script will always be called with sudo, we can get this from the environment.
if [ -z "${SUDO_UID}" ]
then
    echo "Internal error :("     # should never fail, but...
    exit 1
fi
CURRENT_USER=${SUDO_UID}
CURRENT_GROUP=${SUDO_GID}

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
bindfs -u ${CONTAINER_USER} -g ${CONTAINER_GROUP} \
       --create-for-user=${CURRENT_USER} --create-for-group=${CURRENT_GROUP} \
       --chown-deny --chgrp-deny --chmod-normal --realistic-permissions \
       "${OUTSIDE_DIR_IN_HOST}" "${OUTSIDE_DIR_IN_GUEST}"


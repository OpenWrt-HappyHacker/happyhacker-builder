#!/bin/bash

# This script is a horrible, horrible hack to make up for the lack of shared folders in LXD.
# TODO: use real shared folders, somehow... still looking into that one. :(

echo "Downloading output files from container..."

# Sanitize the CONFIG argument.
if (( $# == 0 ))
then
    CONFIG="openwrt-devel"
else
    if [[ -z "$1" ]]
    then
        CONFIG="openwrt-devel"
    else
        CONFIG=$(eval echo $1)
        CONFIG=$(basename $CONFIG)
    fi
fi

# Compress the files we want to upload to the container into a tarfile.
# This may take a long time.
TARFILE="$(lxc exec ${LXD_CONTAINER_NAME} /OUTSIDE/script/guest/prov-lxd-sync-guest-to-host.sh ${CONFIG})"

# Create a temporary directory for us to work with.
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

# Download the tarfile from the container.
lxc file pull "${LXD_CONTAINER_NAME}/${TARFILE}" "${TMP_DIR}/inside.tar.bz2"

# Extract the tarfile.
# This may take a long time.
tar -xaf "${TMP_DIR}/inside.tar.bz2"

# Delete the temporary files.
rm "${TMP_DIR}/inside.tar.bz2"
rmdir "${TMP_DIR}"
lxc exec "${LXD_CONTAINER_NAME}" -- rm "/${TARFILE}"


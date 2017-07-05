#!/bin/bash

# This script is a horrible, horrible hack to make up for the lack of shared folders in LXD.
# TODO: use real shared folders, somehow... still looking into that one. :(

# Create a temporary directory for us to work with.
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

# Compress the files we want to upload to the container into a tarfile.
tar -cjf "${TMP_DIR}/outside.tar.bz2" components/ patches/ profiles/ script/

# Upload the tarfile to the container.
lxc file push "${TMP_DIR}/outside.tar.bz2" "${LXD_CONTAINER_NAME}/root/outside.tar.bz2"

# Delete the temporary files.
rm "${TMP_DIR}/outside.tar.bz2"
rmdir "${TMP_DIR}"

# Upload the LXD shared folder provisioning script to the container.
lxc file push script/guest/prov-lxd-sync-host-to-guest.sh "${LXD_CONTAINER_NAME}/root/prov-lxd-sync-host-to-guest.sh"

# Run the LXD shared folder provisioning script.
lxc exec "${LXD_CONTAINER_NAME}" bash /root/prov-lxd-sync-host-to-guest.sh


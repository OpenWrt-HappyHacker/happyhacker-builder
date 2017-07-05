#!/bin/bash

# LXD hack to implement fake shared folders.
# This script is tailored to the ubuntu LXD container.

# TODO use flock to avoid race conditions

# Fail on error for any line.
set -e

# This is the unprivileged user created by the container.
# It depends on the exact base image you used.
# On the default ubuntu container that is "ubuntu:ubuntu".
INSIDE_USER="ubuntu"
INSIDE_GROUP="ubuntu"

# Make sure the INSIDE and OUTSIDE folders exist.
# This is needed the first time this script is executed, during provisioning.
mkdir -p /INSIDE /OUTSIDE
chown -R ${INSIDE_USER}:${INSIDE_GROUP} /INSIDE /OUTSIDE

# Create a temporary directory for us to work with and switch to it.
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
pushd $TMP_DIR > /dev/null

# Extract the tarfile with the contents of the "shared" folder.
tar -xjf /root/outside.tar.bz2

# Remove the tarfile, we don't need it anymore.
rm /root/outside.tar.bz2

# Fix the ownership of the files.
chown -R ${INSIDE_USER}:${INSIDE_GROUP} .

# Synchronize the contents of the shared folder with the new data.
# Preserve all filesystem permission settings, including ownership.
# Note how this leaves the bin/ directory untouched.
for subdir in ./*/
do
    subdir=$(basename $subdir)
    rsync -avzq --delete "${TMP_DIR}/${subdir}" "/OUTSIDE/"
done

# Clean up the temporary directory.
popd > /dev/null
rm -fr $TMP_DIR


#!/bin/bash

# LXD hack to implement fake shared folders.
# This script is tailored to the ubuntu LXD container.

# Fail on error for any line.
set -e

# Switch to the shared folder.
cd /OUTSIDE

# Sanitize the CONFIG argument.
if (( $# == 0 ))
then
    CONFIG="openwrt-devel"
else
    if [[ -z "$1" ]]
    then
        CONFIG="openwrt-devel"
    else
        CONFIG=$(basename ${1})
    fi
fi

# Compress the files we want to upload to the container into a tarfile.
# This may take a long time.
tar -cjf "/root/${CONFIG}.tar.bz2" $(ls -d "bin/${CONFIG}" "profiles/${CONFIG}/config" "profiles/${CONFIG}/diffconfig" 2>/dev/null)

# Output the name of the tarfile.
echo root/${CONFIG}.tar.bz2


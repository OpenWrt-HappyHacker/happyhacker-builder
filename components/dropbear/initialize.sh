#!/bin/bash
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# If on debug mode, copy the debug configuration.
if [ $DEBUG_MODE -ne 0 ]
then
    cp -r /OUTSIDE/components/dropbear/files-debug/* ./files/
fi

# Create a new SSH keypair.
OUTPUT_DIR="${OUTPUT_DIR}" /OUTSIDE/script/guest/create_dropbear_keys.sh

# Create a Tor hidden service for the SSH server.
OUTPUT_DIR="${OUTPUT_DIR}" /OUTSIDE/script/guest/create_hidden_service.sh dropbear 22

# If requested, set the root password for the device.
if ! [ -z "${ROOT_PASSWORD}" ]
then
    echo "Setting root password for the device..."
    ##echo "Root password is: '${ROOT_PASSWORD}'"         # XXX DEBUG
    /OUTSIDE/script/guest/fetch_default_file.sh base-files /etc/shadow
    gawk -i inplace -F: -v string=$(mkpasswd "${ROOT_PASSWORD}") 'BEGIN{OFS=":"}/root/{gsub(/.*/,string,$2)}1' ./files/etc/shadow
fi

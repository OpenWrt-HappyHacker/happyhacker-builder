#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source /vagrant/script/config.sh

# Define a working source directory.
if (( $# == 0 ))
then
    SOURCE_DIR="openwrt-devel"
else
    if [[ -z "$1" ]]
    then
        SOURCE_DIR="openwrt-devel"
    else
        SOURCE_DIR=`basename "$1"`
    fi
fi

# Get the OpenWrt source code.
cd ~
if [ -e "${SOURCE_DIR}" ]
then
    rm -fr "${SOURCE_DIR}/"
fi
mkdir "${SOURCE_DIR}"
cd "${SOURCE_DIR}"
tar -xaf "../${TAR_FILE}"

# Copy the existing configuration file, if any.
CONFIG_FILE="/vagrant/profiles/${SOURCE_DIR}/config"
DIFF_CONFIG_FILE="/vagrant/profiles/${SOURCE_DIR}/diffconfig"
if [ -e "${CONFIG_FILE}" ]
then
    cp "${CONFIG_FILE}" .config
else
    if [ -e "${DIFF_CONFIG_FILE}" ]
    then
        cp "${DIFF_CONFIG_FILE}" .config
    fi
fi

# Apply the OpenWrt patches.
PATCHES="/vagrant/profiles/${SOURCE_DIR}/patches"
if [ -e "${PATCHES}" ]
then
    while read p
    do
       	if [ -e "/vagrant/patches/$p.diff" ]
        then
            git apply -v "/vagrant/patches/$p.diff"
       	fi
    done < "${PATCHES}"
fi

# Delete the temporary files.
# If we miss this step, sometimes make behaves strangely.
if [ -e tmp/ ]
then
    rm -fr tmp/
    mkdir tmp
fi

# Launch the menuconfig.
make menuconfig

# Copy the full and differential configuration files outside the VM.
mkdir -p "/vagrant/profiles/${SOURCE_DIR}"
cp .config "${CONFIG_FILE}"
./scripts/diffconfig.sh > "${DIFF_CONFIG_FILE}"


#!/bin/bash
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Tell the user what we are doing.
echo "Fetching WiFi Manager configuration file..."

# Check if the WM config file exists.
if ! [ -e "${WIFIDB}" ]
then
    >&2 echo "ERROR: Cannot find WiFi Manager configuration file: ${WIFIDB}"
    exit 1
fi

# Check if it is the default file.
WIFIDB_DEFAULT_HASH=$(md5sum /OUTSIDE/components/wm/default.csv | cut -f 1 -d " ")
if [[ $(md5sum "${WIFIDB}" | grep -F $WIFIDB_DEFAULT_HASH | wc -l) = 1 ]]
then
    >&2 echo "WARNING: WiFi Manager configuration file is the default. Are you sure this is OK?"
fi

# Copy the config file. Make sure the target name is the right one (regardless of the source file).
cp "${WIFIDB}" ./files/etc/wm/wifisdb.csv

# Workaround for a problem when building using the image builder instead of compiling from scratch.
# For some reason, the symlinks to enable the WiFi Manager are not being created.
mkdir -p ./files/etc/rc.d/
ln -s ../init.d/wmd ./files/etc/rc.d/K96wmd
ln -s ../init.d/wmd ./files/etc/rc.d/S96wmd

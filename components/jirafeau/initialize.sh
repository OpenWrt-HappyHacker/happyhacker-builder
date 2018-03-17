#!/bin/bash
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# If on debug mode, copy the debug configuration.
if [ $DEBUG_MODE -ne 0 ]
then
    cp -r /OUTSIDE/components/jirafeau/files-debug/* ./files/
fi

# Create a Tor hidden service for the web server.
OUTPUT_DIR="${OUTPUT_DIR}" /OUTSIDE/script/guest/create_hidden_service.sh jirafeau 443 80

# Get the Tor hidden service hostname.
ONION_HOSTNAME=$(cat ./files/etc/tor/lib/hidden_service/jirafeau/hostname)

# Create a new TLS certificate for the web server.
OUTPUT_DIR="${OUTPUT_DIR}" PROFILE_DIR="${PROFILE_DIR}" /OUTSIDE/script/guest/create_ssl_cert.sh ${ONION_HOSTNAME} ./files/etc/ uhttpd

# Change the Jirafeau configuration file to use the new webroot.
sed -i -r s/\(https?:\\/\\/\)\[^\\/]+/\\1${ONION_HOSTNAME}/g ./files/www/jirafeau/lib/config.local.php

# Make sure the sed command worked correctly.
# Sed doesn't exit with an error condition if the pattern was not found.
grep -qF ${ONION_HOSTNAME} ./files/www/jirafeau/lib/config.local.php

# Add the SD card filesystem fixes we need.
cat /OUTSIDE/components/jirafeau/sdcard_fixes >> ./files/etc/sdcard_fixes.sh

#!/bin/bash

# This script inserts a next-gen hidden service configuration into the torrc configuration file.
# The onion hostname and keys are assumed to have been already created.
# See also the create_hidden_service.sh and create_tor_key.sh scripts.
# Usage:
#    /OUTSIDE/script/guest/add_hidden_service.sh HiddenServiceName port [port port port...]

# Set the error mode to fail on any command.
set -e

# Check if the mandatory arguments are present.
if (( $# < 2 ))
then
    echo "ERROR: Missing command line arguments."
    exit 1
fi

# Get the default torrc file. Does nothing if a custom torrc file was already provided.
/OUTSIDE/script/guest/fetch_default_file.sh tor /etc/tor/torrc

# Prepare the new content to be added to the torrc file.
HIDDEN_SERVICE_DIR="/etc/tor/lib/hidden_service/$1/"
CONFIG_TEXT="HiddenServiceDir ${HIDDEN_SERVICE_DIR}\nHiddenServiceVersion 3\n"
for PORT in "${@:2}"
do
    echo "Adding new next-gen Tor hidden service $1 on port ${PORT}."
    CONFIG_TEXT="${CONFIG_TEXT}HiddenServicePort ${PORT} 127.0.0.1:${PORT}\n"
done

# Add the hidden service configuration to the corresponding section.
sed -i "/################ This section is just for relays #####################/i ${CONFIG_TEXT}" ./files/etc/tor/torrc


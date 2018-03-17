#!/bin/bash

# This script creates a new next-gen Tor hidden service.
# Usage:
#    /OUTSIDE/script/guest/create_hidden_service.sh HiddenServiceName port [port port port...]

# Set the error mode to fail on any command.
set -e

# Check if the mandatory arguments are present.
if (( $# < 2 ))
then
    echo "ERROR: Missing command line arguments."
    exit 1
fi

# Create a new Tor certificate for the hidden service.
mkdir -p "./files/etc/tor/lib/hidden_service/$1/"
/OUTSIDE/script/guest/create_tor_key_v3.sh "./files/etc/tor/lib/hidden_service/$1/"

# Add the configuration to the torrc file.
/OUTSIDE/script/guest/add_hidden_service_v3.sh "$1" "${@:2}"


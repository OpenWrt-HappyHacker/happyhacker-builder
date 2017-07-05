#!/bin/bash

# This script creates a new Tor hidden service.
# Arguments:
#    1) The name of the hidden service.
#    2) The port it will listen on.

# Set the error mode to fail on any command.
set -e

# Create a new Tor certificate for the hidden service.
mkdir -p "./files/etc/tor/lib/hidden_service/$1/"
/OUTSIDE/script/guest/create_tor_key.sh "./files/etc/tor/lib/hidden_service/$1/"

# Add the new hidden service to the torrc configuration file.
# Note: the path given here must be valid on the device, not
#       the builder, hence we don't prefix it with "./files/".
/OUTSIDE/script/guest/add_hidden_service.sh "/etc/tor/lib/hidden_service/$1/" $2 127.0.0.1:$2

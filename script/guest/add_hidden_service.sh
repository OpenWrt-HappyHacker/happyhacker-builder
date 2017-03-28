#!/bin/bash

# This script inserts a new hidden service into the torrc configuration file.
#
# The arguments are:
#  1) Hidden service directory (mandatory).
#  2) Hidden service listening port (mandatory).
#  3) Hidden service connecting IP and port (mandatory).
#  4) Location of the torrc configuration file (optional, defaults to "./files/etc/tor/torrc").
#
# Example:
#     add_hidden_service.sh /etc/tor/lib/my_hidden_web_server/ 443 127.0.0.1:443
#
# No sanitization of arguments is performed, since arguments are assumed to be
# constants defined in the build configuration. If any user provided data is
# ever used here, it must be sanitized before calling this script.

# Check if the mandatory arguments are present.
if (( $# < 3 ))
then
    echo "ERROR: Missing command line arguments."
    exit 1
fi

# Check for too many arguments being passed.
if (( $# > 4 ))
then
    echo "ERROR: Too many command line arguments."
    exit 1
fi

# Get the optional argument.
TORRC_FILE="./files/etc/tor/torrc"
if (( $# == 4 ))
then
    TORRC_FILE="$4"
fi

# Lock access to the torrc file to avoid race conditions.
(
    flock -x 200

    # Add the hidden service configuration to the corresponding section.
    sed -i "/################ This section is just for relays #####################/i HiddenServiceDir \"$1\"\nHiddenServicePort $2 $3\n" "${TORRC_FILE}"

# Release the lock on the torrc file.
) 200>$(dirname "${TORRC_FILE}")/.lockfile

# Tell the user about it.
echo "Added new Tor hidden service on port $2."


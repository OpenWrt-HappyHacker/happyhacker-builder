#!/bin/bash

# This script sets the order of execution of each service script in init.d.
# The first argument is the name of the package where the service is.
# The second argument is the script name (without the path component).
# The third argument is the START number (1-99).
# The fourth (optional) argument is the STOP number (1-99).

# Set the error mode to fail on any command.
set -e

# Check the command line arguments.
if (( $# < 3 ))
then
    >&2 echo "Error: not enough arguments provided"
    exit 1
fi
if (( $# > 4 ))
then
    >&2 echo "Error: too many arguments provided"
    exit 1
fi

# Get the arguments.
PACKAGE="$1"
FILENAME="./files/etc/init.d/$2"
SCRIPT="/etc/init.d/$2"
START=$3
STOP=$4

# Fetch the service script file.
/OUTSIDE/script/guest/fetch_default_file.sh "${PACKAGE}" "${SCRIPT}"

# Set the START number.
sed -i s/^START=.*$/START=$START/ "${FILENAME}"

# Set the STOP number (if requested).
if ! [ -z "$STOP" ]
then
    if [ $(grep -qx "STOP=.*" "${FILENAME}") -eq 0 ]
    then
        sed -i s/^STOP=.*$/STOP=$STOP/ "${FILENAME}"
    else
        sed -i s/^START=.*$/a\ STOP=$STOP "${FILENAME}"
    fi
fi

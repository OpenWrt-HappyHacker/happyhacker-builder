#!/bin/bash

# This script sets up a temporary hidden service on Tor to force Tor to create a new private key.
# It depends on the setup of Tor done during the provisioning of the VM (see provision.sh).
#
# The script accepts an optional argument with a directory where to copy the new keys. It exits
# with errorcode 0 if successful, 1 on error. No text output of any kind is generated.
#
# This implementation may soon be replaced by simply an OpenSSL command that does the same, but
# for now we will use this to ensure future compatibility (and minimal fuzz on our side).

# Set the error mode to fail on any command.
set -e

# Lock access to this directory, we don't want concurrency problems.
(
    flock -x 200

    # Switch to the hidden service work directory, and preserve the current directory.
    # We need this to resolve relative paths passed as arguments.
    pushd ~/.hiddenservice >/dev/null 2>&1

    # Remove previously generated keys.
    if [ -f hostname ]
    then
        rm hostname
    fi
    if [ -f private_key ]
    then
        rm private_key
    fi

    # Let Tor create a new hidden service key.
    tor -f torrc >/dev/null 2>&1 &
    pid=$!

    # Wait for Tor to halt (since in our configuration we forbade it from connecting anywhere).
    # When the files we want are created, kill the Tor process. After 10 seconds of waiting,
    # kill the process anyway even if no files are created and error out.
    max=100
    until [ -f hostname ] && [ -f private_key ]
    do
        sleep 0.1
        max=$(($max-1))
        if [ max == 0 ]
        then
            # Kill Tor on timeout and exit with error code 1.
            kill -9 $pid >/dev/null 2>&1
            popd >/dev/null 2>&1
            exit 1
        fi
    done

    # Kill the Tor process.
    kill $pid >/dev/null 2>&1

    # Return to the original working directory.
    # Now we can resolve relative paths given as arguments.
    popd >/dev/null 2>&1

    # If we got an argument, it's a path of where to copy the new files.
    # Extra arguments are silently ignored.
    # if no arguments are given, the caller will have to take care of fetching the files.
    if (( $# >= 1 ))
    then
        cp ~/.hiddenservice/hostname ~/.hiddenservice/private_key "$1"
    fi

    # Tell the user we succeeded.
    echo "Tor hidden service keys created for: $(cat ~/.hiddenservice/hostname)"

# Release the lock file.
) 200>~/.hiddenservice/.lockfile

# Exit gracefully.
exit 0

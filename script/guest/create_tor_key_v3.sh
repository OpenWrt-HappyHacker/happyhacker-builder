#!/bin/bash

# This script creates the private key and .onion hostname for a next-gen hidden service.
# Since creation of these keys is a bit more complex we're not yet doing it ourselves,
# but rather invoking Tor itself to do it for us. This requires some bash black magic.
# Currently, version 3 of the hidden services is only available since Tor 0.3 alpha,
# so for this to work, the provisioning scripts must download the source code and compile
# it. For all these reasons (and others) support for v3 is optional.

# Set the error mode to fail on any command.
set -e

# Check the command line parameters.
if (( $# < 1 ))
then
    >&2 echo "ERROR: not enough arguments."
    exit 1
fi
if (( $# >= 2 ))
then
    >&2 echo "ERROR: too many arguments."
    exit 1
fi

# Show a message so the user knows what's going on.
echo "Generating Tor next-gen hidden service keys..."

# Determine if we have Tor version 0.3 or later installed.
if ! [[ $(tor --version 2> /dev/null | grep "^Tor version 0\.3\." | wc -l) == 1 ]]
then
    >&2 echo "ERROR: Tor version 0.3 or greater not found."
    exit 1
fi

# Lock access to this directory, we don't want concurrency problems.
mkdir -p ~/.hiddenservice
(
    flock -x 200

    # Switch to the hidden service work directory, and preserve the current directory.
    # We need this to resolve relative paths passed as arguments.
    pushd ~/.hiddenservice >/dev/null 2>&1

    # Remove any files accidentally left here.
    # This should not happen, but let's make sure.
    rm -f torrc hostname hs_ed25519_secret_key hs_ed25519_public_key

    # Let Tor create a new hidden service key.
    cat >torrc <<EOF
DisableNetwork 1
RunAsDaemon 0
PortForwarding 0
ControlPort 0
DirPort 0
ORPort 0
HiddenServiceDir .
HiddenServiceVersion 3
HiddenServicePort 65534 127.0.0.1:65534
EOF
    chmod 700 .
    tor -f torrc >/dev/null 2>&1 &
    pid=$!

    # Wait for Tor to halt (since in our configuration we forbade it from connecting anywhere).
    # When the files we want are created, kill the Tor process. After 10 seconds of waiting,
    # kill the process anyway even if no files are created and error out.
    max=100
    until [ -f hostname ] && [ -f hs_ed25519_secret_key ] && [ -f hs_ed25519_public_key ]
    do
        sleep 0.1
        max=$(($max-1))
        if [[ $max == 0 ]]
        then
            # Kill Tor on timeout and exit with error code 1.
            kill -9 $pid >/dev/null 2>&1
            rm -f torrc hostname hs_ed25519_secret_key hs_ed25519_public_key
            popd >/dev/null 2>&1
            exit 1
        fi
    done

    # Kill the Tor process.
    kill $pid >/dev/null 2>&1

    # Return to the original working directory.
    # Now we can resolve relative paths given as arguments.
    popd >/dev/null 2>&1

    # Move the hidden service files to the output directory.
    mkdir -p -- "$1"
    mv -- ~/.hiddenservice/hostname ~/.hiddenservice/hs_ed25519_secret_key ~/.hiddenservice/hs_ed25519_public_key "$1"

# Release the lock file.
) 200>~/.hiddenservice/.lockfile

# Tell the user we succeeded.
echo "Tor hidden service private key stored in: $1/hs_ed25519_secret_key"
cat -- "$1/hostname" | awk '{print "Tor hidden service hostname is: "$$1}'

# Exit gracefully.
exit 0


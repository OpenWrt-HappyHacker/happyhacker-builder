#!/bin/bash

# This script creates a new SSH key pair. It takes the key generation arguments from the
# global configuration file and drops the new private and public keys in root's home
# directory.
#
# Future versions of this script will drop the keys in the bin/ directory outside the VM
# instead, to avoid bundling the private key with the device, which is not really needed.

# Set the error mode to fail on any command.
set -e

# Check the command line arguments.
if (( $# > 2 ))
then
    >&2 echo "Error: too many arguments provided"
    exit 1
fi

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Generate the keypair.
echo "Generating new SSH keypair..."
mkdir -p ./files/root/
if [ -z "${SSH_PASSPHRASE+x}" ]
then
    ssh-keygen -q -b $SSH_KEYLENGTH -t $SSH_TYPE -f "./files/root/${SSH_KEYFILE}"
else
    if [ -z "${SSH_PASSPHRASE}" ]
    then
        echo "WARNING: using an empty passphrase for the SSH private key"
    fi
    ssh-keygen -q -b $SSH_KEYLENGTH -t $SSH_TYPE -f "./files/root/${SSH_KEYFILE}" -N "${SSH_PASSPHRASE}"
fi
chmod 400 "./files/root/${SSH_KEYFILE}"
chmod 444 "./files/root/${SSH_KEYFILE}.pub"

# Add the public key to the authorized keys list for the device.
mkdir -p ./files/etc/dropbear/
cat "./files/root/${SSH_KEYFILE}.pub" >> ./files/etc/dropbear/authorized_keys
chmod 600 ./files/etc/dropbear/authorized_keys


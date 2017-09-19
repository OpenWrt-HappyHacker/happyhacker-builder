#!/bin/bash

# This script creates a new SSH key pair. It takes the key generation arguments from the
# global configuration file and drops the new private and public keys in root's home
# directory.
#
# Future versions of this script will drop the keys in the bin/ directory outside the VM
# instead, to avoid bundling the private key with the device, which is not really needed.

# Set the error mode to fail on any command.
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Generate the keypair and place the keys in the build output directory.
# We may need to use dropbear for this, because there might be incompatibilities with openssh.
# In particular, openssh uses algorithms that dropbear does not support.
# The downside: dropbear does not support encrypted private keys, so we cannot use a passphrase.
echo "Generating new Dropbear keypair..."
mkdir -p "${OUTPUT_DIR}/keys/dropbear"
dropbearkey -s $SSH_KEYLENGTH -t $SSH_TYPE -f "${OUTPUT_DIR}/keys/dropbear/${SSH_KEYFILE}" | grep "^ssh-rsa " > "${OUTPUT_DIR}/keys/dropbear/${SSH_KEYFILE}.pub"

# Add the public key to the authorized keys list for the device.
mkdir -p ./files/etc/dropbear/
cat "${OUTPUT_DIR}/keys/dropbear/${SSH_KEYFILE}.pub" >> ./files/etc/dropbear/authorized_keys
chmod 600 ./files/etc/dropbear/authorized_keys

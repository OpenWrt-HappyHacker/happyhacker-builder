#!/bin/bash

# Set the error mode to fail on any command.
set -e

# Load the build configuration variables.
source /vagrant/script/config.sh

# Copy the SSH keys to the output directory.
mkdir -p "${OUTPUT_DIR}/keys/dropbear"
cp "./files/root/${SSH_KEYFILE}" "${OUTPUT_DIR}/keys/dropbear/"
cp "./files/root/${SSH_KEYFILE}.pub" "${OUTPUT_DIR}/keys/dropbear/"

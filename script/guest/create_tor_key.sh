#!/bin/bash

# This script creates the private key and .onion hostname for a hidden service.

# Set the error mode to fail on any command.
set -e

# Show a message so the user knows what's going on.
echo "Generating Tor hidden service keys..."

# Generate the RSA private key in PEM format for the hidden service.
openssl genrsa -out "$1/private_key" 1024

# Extract the .onion hostname from the public key.
openssl pkey -pubout -inform pem -outform der -in "$1/private_key" -out "$1/public_key"
python /OUTSIDE/script/guest/calc_onion_hostname.py "$1/public_key" > "$1/hostname"

# Tell the user we succeeded.
echo "Tor hidden service private key stored in: $1/private_key"
cat "$1/hostname" | awk '{print "Tor hidden service hostname is: "$$1}'


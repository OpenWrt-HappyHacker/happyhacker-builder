#!/bin/bash

# This script creates the private key and .onion hostname for a hidden service.

# Set the error mode to fail on any command.
set -e

# Show a message so the user knows what's going on.
echo "Generating Tor hidden service keys..."

# Generate the RSA private key in PEM format for the hidden service.
openssl genrsa -out "$1/private_key" 1024

# Extract the .onion hostname from the public key.
# What it does, step by step:
#   1) Extract the public key in SPKI form from the private key.
#   2) Remove the first 22 bytes (the header).
#   3) Calculate the SHA1 hash in hexadecimal format.
#   4) Decode the hash from hexadecimal to raw bytes.
#   5) Re-encode the hash in Base32 format.
#   6) Drop the last half of the hash.
#   7) Convert to lowercase and append the ".onion" extension.
openssl pkey -pubout -inform pem -outform der -in "$1/private_key" | tail -c +23 | sha1sum -b | head -c +40 | xxd -r -p | python -c "import sys, base64; sys.stdout.write( base64.b32encode( sys.stdin.readline() ) )" | head -c +16 | tr '[:upper:]' '[:lower:]' | awk '{print $$1".onion"}' > "$1/hostname"

# Tell the user we succeeded.
echo "Tor hidden service private key stored in: $1/private_key"
cat "$1/hostname" | awk '{print "Tor hidden service hostname is: "$$1}'

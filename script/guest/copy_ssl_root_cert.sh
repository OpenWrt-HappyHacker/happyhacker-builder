#!/bin/bash

# This script copies the root SSL certificate used by create_ssl_cert.sh.

# Check the command line arguments.
if (( $# < 1 ))
then
    >&2 echo "Error: not enough arguments provided"
    exit 1
fi
if (( $# > 1 ))
then
    >&2 echo "Error: too many arguments provided"
    exit 1
fi

# Paths to the per-profile root certificate files.
# If for some reason we don't have a profile set, use the global ones.
if [ -z "${PROFILE_DIR}" ]
then
    >&2 echo "Warning: no profile set, using global CA settings"
    CA_KEY="/vagrant/script/data/ca.key"
    CA_CERT="/vagrant/script/data/ca.crt"
else
    CA_KEY="${PROFILE_DIR}/ca.key"
    CA_CERT="${PROFILE_DIR}/ca.crt"
fi

# Copy the root certificate files.
mkdir -p -- "$1/"
cp -- "${CA_KEY}" "$1/ca.key"
cp -- "${CA_CERT}" "$1/ca.crt"
echo "Copied root SSL certificates to: $1/"

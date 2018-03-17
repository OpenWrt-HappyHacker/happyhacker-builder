#!/bin/bash
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Create a Tor hidden service for the OpenVPN server.
OUTPUT_DIR="${OUTPUT_DIR}" /OUTSIDE/script/guest/create_hidden_service.sh openvpn 1194

# Get the Tor hidden service hostname.
ONION_HOSTNAME=$(cat ./files/etc/tor/lib/hidden_service/openvpn/hostname)

# Create a new TLS certificate for the OpenVPN server.
OUTPUT_DIR="${OUTPUT_DIR}" PROFILE_DIR="${PROFILE_DIR}" /OUTSIDE/script/guest/create_ssl_cert.sh ${ONION_HOSTNAME} ./files/etc/openvpn/ssl openvpn

# Generate the OpenVPN server configuration file.




# XXX TODO

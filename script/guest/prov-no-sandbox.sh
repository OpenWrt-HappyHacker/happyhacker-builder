#!/bin/bash

# Provisioning script when not using a sandbox.
# It probably makes more sense when running it inside your own VM or container or whatever.
# Assumes an Ubuntu 16.04 64 bit environment.

###################################################################################
# WARNING: this script will make changes to the host system! IT MAY BREAK THINGS! #
###################################################################################

# Fail on error for any line.
set -e

# Load the build configuration variables.
source script/config.sh

# Set up the /INSIDE and /OUTSIDE directories.
mkdir -p build
chown -R $1:$2 build
ln -sf $(realpath ./build/) /INSIDE
ln -sf $(realpath .) /OUTSIDE

# Change the DNS servers to OpenDNS.
# OpenWrt builds require downloading several files from the Internet,
# using OpenDNS often speeds it up and gets better results.
# Temporary DNS resolution failures can cause the whole build to fail.
# (Plus, we avoid leaking DNS queries to our ISP).
echo "nameserver 208.67.220.220" > /etc/resolv.conf
echo "nameserver 208.67.222.222" >> /etc/resolv.conf
LINE="prepend domain-name-servers 208.67.222.222, 208.67.220.220;"
FILE="/etc/dhcp/dhclient.conf"
grep -q "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

# Setup the required packages.
# This script runs as root.
source /OUTSIDE/script/guest/prov-packages.sh

# Mark the environment as provisioned.
touch /OUTSIDE/.provisioned

# Print the last banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "DONE"
>&2 echo "---------------------------------------------------------------------"


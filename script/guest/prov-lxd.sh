#!/bin/bash

# LXD-specific provisioning script.
# Most of the work is done by other scripts, this
# just contains the LXD bits in between them.

# This script is tailored to the ubuntu LXD container.

# Fail on error for any line.
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Create the /INSIDE directory.
if ! [ -e /INSIDE ]
then
    ln -s /home/${LXD_INSIDE_USER} /INSIDE
fi

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

# Enable networking if needed.
if [[ "$(cat /sys/class/net/${LXD_INSIDE_IFACE}/operstate)" != "up" ]]
then
  ifconfig ${LXD_INSIDE_IFACE} up
  dhclient ${LXD_INSIDE_IFACE}
fi

# Setup the required packages.
# This script runs as root.
source /OUTSIDE/script/guest/prov-packages.sh

# Setup the home folder in the container.
# This script runs as an unprivileged user.
su ${LXD_INSIDE_USER} -c /OUTSIDE/script/guest/prov-lxd-user.sh

# Setup the build environment.
# This script runs as an unprivileged user.
su ${LXD_INSIDE_USER} -c /OUTSIDE/script/guest/prov-environment.sh

# Mark the container as provisioned.
touch /.provisioned

# Print the last banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "DONE"
>&2 echo "---------------------------------------------------------------------"


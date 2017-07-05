#!/bin/bash

# Vagrant-specific provisioning script.
# Most of the work is done by other scripts, this
# just contains the Vagrant bits in between them.

# This script is tailored to the ubuntu/trusty64 box.

# Fail on error for any line.
set -e

# This is the unprivileged user created by Vagrant.
# It depends on the exact Vagrant box you used.
# On the ubuntu/trusty64 box that is "vagrant".
VAGRANT_USER="vagrant"

# Create the /INSIDE and /OUTSIDE directories.
# For Vagrant, these will be symlinks to the
# unprivileged user's home directory and the
# VirtualBox shared folder respectively.
if ! [ -e /INSIDE ]
then
    ln -s /home/${VAGRANT_USER} /INSIDE
fi
if ! [ -e /OUTSIDE ]
then
    ln -s /vagrant /OUTSIDE
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

# Setup the required packages.
# This script runs as root.
source /OUTSIDE/script/guest/prov-packages.sh

# Setup the vagrant home folder.
su ${VAGRANT_USER} -c /OUTSIDE/script/guest/prov-vagrant-user.sh

# Setup the build environment.
# This script runs as an unprivileged user.
su ${VAGRANT_USER} -c /OUTSIDE/script/guest/prov-environment.sh

# Print the last banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "DONE"
>&2 echo "---------------------------------------------------------------------"


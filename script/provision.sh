#!/bin/bash

# Fail on error for any line.
set -e

# Print the banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "INSTALLING REQUIRED PACKAGES"
>&2 echo "---------------------------------------------------------------------"

# Change the DNS servers to OpenDNS. (if not it's a container)
if ! [ "$container" == "docker"  ]; then
    LINE="prepend domain-name-servers 208.67.222.222, 208.67.220.220;"
    FILE="/etc/dhcp/dhclient.conf"
    grep -q "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
fi


# Copy our custom Wget configuration file.
cp /vagrant/script/wgetrc .wgetrc

# Update the package list.
apt-get update

# Install the Haveged daemon. This should somewhat improve the entropy pool.
# We need a good entropy pool to generate the various keys we need.
apt-get install -y haveged

# Install all possible dependencies for all OpenWrt packages.
# This is more than we need right now but it covers all future possibilities,
# as well as what users may want in their custom ROMs.
apt-get install -y asciidoc bash bc bcc bin86 binutils build-essential bzip2 \
	fastjar flex g++ gawk gcc gcc-multilib genisoimage gettext git-core \
	intltool jikespg libboost-dev libgtk2.0-dev libncurses5-dev libssl-dev \
	libusb-dev libxml-parser-perl make mercurial openjdk-7-jdk patch \
	perl-modules python-dev rsync ruby sdcc sharutils subversion unzip \
	util-linux wget xsltproc zlib1g-dev

# The following packages are required by our scripts.
apt-get install -y colorgcc colormake coreutils makepasswd

# Install Tor and immediately stop the daemon.
# We will use it only to generate hidden service keys, it will not connect
# to the rest of the Tor network at any time.

# if not it's in docker image building process
if ! [ -e "/vagrant/building" ]; then
    apt-get install -y tor
    service tor stop
    sed -i s/RUN_DAEMON\\=\\\"yes\\\"/RUN_DAEMON=\"no\"/g /etc/default/tor
    cp /vagrant/script/torrc_global /etc/tor/torrc
    mkdir -p /home/vagrant/.hiddenservice
    cp /vagrant/script/torrc_local /home/vagrant/.hiddenservice/torrc
    chown -R vagrant:vagrant /home/vagrant/.hiddenservice
fi


# Print the second banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "DOWNLOADING OPENWRT SOURCE CODE"
>&2 echo "---------------------------------------------------------------------"

# Setup script. Runs as an unprivileged user.
# Do not try to run this script as root, things may break!
su vagrant -c /vagrant/script/setup.sh

# Print the last banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "DONE"
>&2 echo "---------------------------------------------------------------------"


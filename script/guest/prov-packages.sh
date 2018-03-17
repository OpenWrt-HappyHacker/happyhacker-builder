#!/bin/bash

# This script provisions the VM (or container) with the required packages.
# It requires a privileged user.

# Fail on error for any line.
set -e

# Print the banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "INSTALLING REQUIRED PACKAGES"
>&2 echo "---------------------------------------------------------------------"

# Update the package list.
apt-get update

# Install the Haveged daemon. This should somewhat improve the entropy pool.
# We need a good entropy pool to generate the various keys we need.
apt-get install -y haveged

# Install the OpenWrt dependencies listed in their web page.
apt-get install -y build-essential subversion libncurses5-dev zlib1g-dev \
	gawk gcc-multilib flex git-core gettext libssl-dev unzip

# Install some extra dependencies mentioned elsewhere in the web page.
# Some may not be actually needed, but let's stay on the safe side.
apt-get install -y asciidoc bc bcc bin86 fastjar genisoimage gettext intltool \
	jikespg libboost-dev libgtk2.0-dev libusb-dev libxml-parser-perl mercurial \
	patch perl-modules python-dev rsync ruby sdcc sharutils util-linux wget \
	xsltproc

# Optionally install the Java JDK (some OpenWrt packages may require it).
# The latest available version may depend on the version on Debian/Ubuntu
# and sadly there is no generic metapackage to refer to it.
# This is a really large dependency, only enable it if you plan to use Java
# in your device (for whatever reason...).
#apt-get install -y openjdk-7-jdk	# Ubuntu 14 (Trusty Tahr)
#apt-get install -y openjdk-8-jdk
#apt-get install -y openjdk-9-jdk	# Ubuntu 16 (Xenial Xerus)

# The following packages are required by our scripts.
apt-get install -y bzip2 colorgcc colormake coreutils makepasswd uuid-runtime whois

# The dropbear package changes its name depending on the Ubuntu version.
if [[ $(apt-cache search dropbear-bin | wc -l) == 1 ]]
then
    apt-get install -y dropbear-bin
else
    apt-get install -y dropbear
fi

# Old versions of Ubuntu didn't have the "realpath" command by default.
if [[ $(which realpath | wc -l) == 0 ]]
then
    apt-get install -y realpath
fi

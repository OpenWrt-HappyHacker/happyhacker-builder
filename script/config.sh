# This is the configuration for the build system.
# You need to read this before doing anything else!
# Make sure you read each and every option.

# Unless specified, all settings here are mandatory.
# If a mandatory value is missing, things may fail spectacularly.

#------------------------------------------------------------------------------#
# Build settings.
#------------------------------------------------------------------------------#

# Set the sandbox (virtualization/container) provider.
# Valid values are "none", "docker", "lxd" and "vagrant".
# The special value "error" will cause an error to remind you to edit this. :)
SANDBOX_PROVIDER="lxd"

# Number of parallel Make jobs. If ommitted it will default to the number of
# cores (NUM_CORES). In our tests OpenWrt wouldn't build correctly in parallel
# under some circumstances, if that happens to you set it to 1 to disable this
# feature completely.
#MAKE_JOBS=1

# Turn verbose mode on (1) or off (0). Implies MAKE_JOBS=1.
# Use this if your builds are failing to find out why.
VERBOSE=0

#------------------------------------------------------------------------------#
# Docker settings.
#------------------------------------------------------------------------------#

# The following settings only apply when SANDBOX_PROVIDER is "docker".
# You don't normally need to change any of these settings.
# WARNING: Docker support is experimental and has very little testing.

# Container default conf
CNT_TP="nimmis/alpine-micro"
CNT_NM="BuilderNG" # Pass name as script argument
CNT_TG="HHv1" # container version tag

CNT_USR="maker"
CNT_USR_HOME="/home/$CNT_USR"
CNT_SHAREPATH="/OUTSIDE"

CNT_SSHD=0 # 1:enable/0:disable sshd support

HST_BASEDIR="$(pwd)"
#HST_SHAREPATH="$HST_BASEDIR/INSIDE"
HST_SHAREPATH="$HST_BASEDIR"

#------------------------------------------------------------------------------#
# LXD settings.
#------------------------------------------------------------------------------#

# The following settings only apply when SANDBOX_PROVIDER is "lxd".
# This is the recommended provider if your host OS is Ubuntu.
# You don't normally need to change any of these settings.

# Remote image to build the container with.
LXD_REMOTE_IMAGE="ubuntu:16.04"

# Name of the profile.
LXD_PROFILE_NAME="happyhacker-prf"

# Name of the build container.
LXD_CONTAINER_NAME="happyhacker-ctr"

# Name of the build container's network.
LXD_NETWORK_NAME="happyhacker-net"

# Name of the unprivileged user and group inside the container.
# It depends on the exact base image you used.
# On the default ubuntu 16.04 container that is "ubuntu:ubuntu".
LXD_INSIDE_USER="ubuntu"
LXD_INSIDE_GROUP="ubuntu"

# This is the network interface used by the container.
# It depends on the exact base image you used.
# On the default ubuntu 16.04 container that is "eth0".
LXD_INSIDE_IFACE="eth0"

#------------------------------------------------------------------------------#
# Vagrant settings.
#------------------------------------------------------------------------------#

# The following settings only apply when SANDBOX_PROVIDER is "vagrant".
# This is the recommended provider on Debian and Fedora. Hasn't been tested in
# other Linux distributions, so your mileage may vary.
# You will very much want to review these settings! :)

# When using Vagrant, set the virtualization provider.
# Only VirtualBox was tested.
VIRT_PROVIDER="virtualbox"

# Number of CPU cores to give to the build VM.
# One core is more conservative and easier to debug, but slower.
# We recommend using 4 cores for quicker builds.
# See also the MAKE_JOBS setting.
NUM_CORES=4

# Amount of RAM in megabytes to give to the build VM.
# Will not work without AT LEAST 4 gigabytes.
# Make sure not to assign more RAM than you actually have, of course.
VM_MEMORY=8192

#------------------------------------------------------------------------------#
# Advanced build settings.
#------------------------------------------------------------------------------#

# Enable the debug mode.
# This is used internally by the developers, you probably don't need it.
# WARNING: Debug builds SHOULD NOT be used in production, EVER.
#          They are intentionally insecure by default!
DEBUG_MODE=0
##DEBUG_MODE=1

# Directory where build files will be written to temporarily.
# Contents may be deleted when the build is finished.
# Normally you never need to change this.
BUILD_BASEDIR="/INSIDE"

#------------------------------------------------------------------------------#
# Device Settings.
#------------------------------------------------------------------------------#

# Root password for the device.
# You should probably change this. :)
#ROOT_PASSWORD="a zueira nao tem fin"
ROOT_PASSWORD="toor"

# Location of the CSV file with the WiFi SSIDs and passwords.
# The first line of the file is ignored, everything else is a list of
# wireless network IDs and passwords. The device will try to connect to
# these automatically when it boots.
#
# PAY ATTENTION TO THIS! Make sure to add at least one network here.
# If you neglect to do that, you'll be unable to SSH to your device!
# Make sure to edit its contents before building the firmware image.
#
WIFIDB="/OUTSIDE/script/data/wifisdb.csv"

#------------------------------------------------------------------------------#
# SSL/TLS certificate settings.
#------------------------------------------------------------------------------#

# Expiry time of the certificates.
CA_CERT_DAYS=1826
SSL_CERT_DAYS=730

# Key size. 4096 bits recommended.
SSL_KEY_SIZE=4096

# Default values for testing.
# For real use we recommend to leave them empty or use fake values instead.
CA_CERT_COUNTRY="PL"
CA_CERT_STATE="Województwo małopolskie"
CA_CERT_CITY="Kraków"
CA_CERT_COMPANY="AlligatorCon"
CA_CERT_UNIT="Happy Hacker Automatically Generated Root Certificate"
CA_CERT_DN="alligatorcon.pl"
CA_CERT_EMAIL="crapula@alligatorcon.pl"

#CA_CERT_COUNTRY=""
#CA_CERT_STATE=""
#CA_CERT_CITY=""
#CA_CERT_COMPANY=""
#CA_CERT_UNIT=""
#CA_CERT_DN=""
#CA_CERT_EMAIL=""

#------------------------------------------------------------------------------#
# SSH key generation settings.
#------------------------------------------------------------------------------#

# Optional passphrase to encrypt the private key.
# Leave empty to disable (this is less secure!).
# Comment out to prompt the user during the build.
# Note that this feature is only supported by OpenSSH, not Dropbear.
SSH_PASSPHRASE="a zueira nao tem fin"

# Key type and length, and filename. Normally you don't need to change this.
# If you're extra paranoid, try increasing the RSA key size to 4096.
# Elliptic curves may be a good idea too if you're using OpenSSH, however we
# have NOT tested this on a real device, so you may end up bricking it...
SSH_KEYLENGTH=2048
SSH_TYPE="rsa"
SSH_KEYFILE="id_rsa"

#------------------------------------------------------------------------------#
# OpenWrt source code location.
#------------------------------------------------------------------------------#

# OpenWrt 15.05 Chaos Calmer. This is the one we support.
REPO_URL="https://git.openwrt.org/15.05/openwrt.git"

# Latest version of OpenWrt. We don't currently support it. In theory it should
# work on Zsun devices, but it didn't work well in our tests, specifically we
# couldn't mount the MicroSD. If you managed to get it to work, let us know!
#REPO_URL="https://github.com/openwrt/openwrt.git"

# LEDE source repository.
# LEDE is a fork of OpenWrt focused on stability and security.
# Support for LEDE is currently experimental and should be used with caution.
#REPO_URL="https://git.lede-project.org/source.git"
#REPO_URL="https://github.com/lede-project/source.git"

# Optionally use a specific commit. This freezes the code to the point we want,
# so further upstream commits don't break our patches.
# Comment out this line to always use the latest commit.
# OpenWrt 15.05 stable commit: 9a1fd3e313cedf1e689f6f4e342528ed27c09766
REPO_COMMIT="9a1fd3e313cedf1e689f6f4e342528ed27c09766"

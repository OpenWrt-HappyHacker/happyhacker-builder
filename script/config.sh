# This is the configuration for the build system.
# Don't change this unless you know what you are doing!

# Particularly refrain from adding anynthing other than variables here,
# since it's a Bash/Ruby polyglot file.

#------------------------------------------------------------------------------#
# Build VM settings.
#------------------------------------------------------------------------------#

# Set the sandbox (virtualization/container) provider.
# Valid values are "docker" and "vagrant".
SANDBOX_PROVIDER="vagrant"

# When using Vagrant, set the virtualization provider.
# Only VirtualBox was tested.
# This setting is ignored when using Docker.
VIRT_PROVIDER="virtualbox"

# Number of CPU cores to give to the build VM.
# One core is more conservative and easier to debug, but slower.
# We recommend using 4 cores for quicker builds.
# See also the MAKE_JOBS setting.
NUM_CORES=1

# Amount of RAM in megabytes to give to the build VM.
# Will not work without AT LEAST 4 gigabytes.
# This setting is ignored when using Docker.
VM_MEMORY=4096

# Container settings when using Docker.
# This is ignored when using Vagrant.
CNT_TP="happyhacker/openwrtbuilder:0.1"
CNT_NM="hh-builder"

#------------------------------------------------------------------------------#
# Build settings.
#------------------------------------------------------------------------------#

# Number of parallel Make jobs. If ommitted it will default to the number of
# cores (NUM_CORES). In our tests OpenWrt wouldn't build correctly in parallel
# under some circumstances, if that happens to you set it to 1 to disable this
# feature completely.
#MAKE_JOBS=1

# Turn verbose mode on (1) or off (0). Implies MAKE_JOBS=1.
VERBOSE=0

# Cache where the original, unmodified OpenWrt source code will be kept.
# Normally you never need to change this.
TAR_FILE="openwrt.tar.bz2"

#------------------------------------------------------------------------------#
# SSL/TLS certificate settings.
#------------------------------------------------------------------------------#

# Paths to the root certificate files.
# Normally you never need to change this.
CA_KEY="/vagrant/script/ca.key"
CA_CERT="/vagrant/script/ca.crt"

# Expiry time of the certificates.
CA_CERT_DAYS=1826
SSL_CERT_DAYS=730

# Key size. 4096 bytes recommended.
SSL_KEY_SIZE=4096

# Default values for testing.
# For real use we recommend to leave them empty or use fake values instead.
CA_CERT_COUNTRY="PL"
CA_CERT_STATE="Województwo małopolskie"
CA_CERT_CITY="Kraków"
CA_CERT_COMPANY="AlligatorCon"
CA_CERT_UNIT="Happy Hacker Automatically Generated Root Certificate"
CA_CERT_DN="alligatorcon.pl"
CA_CERT_EMAIL="info@alligatorcon.pl"

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
SSH_PASSPHRASE="alligator"

# Key type and length, and filename. Normally you don't need to change this.
# If you're extra paranoid, try increasing the RSA key size to 4096.
SSH_KEYLENGTH=2048
SSH_TYPE="rsa"
SSH_KEYFILE="id_rsa"

#------------------------------------------------------------------------------#
# OpenWrt source code location.
#------------------------------------------------------------------------------#

# OpenWrt 15.05 Chaos Calmer. This is the one we support.
REPO_URL="https://git.openwrt.org/15.05/openwrt.git"

# Bleeding edge version. This is experimental, and won't work out of the box.
#REPO_URL="https://git.openwrt.org/openwrt.git"

# Specific ZSUN version we were using in the beginning.
# Not recommended - it was based on an older branch of Chaos Calmer.
# We left it here only for testing.
#REPO_URL="https://github.com/Emeryth/openwrt-zsun.git"


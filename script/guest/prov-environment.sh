#!/bin/bash

# This script prepares the environment inside the VM (or container)
# to build OpenWrt. It does not require a privileged user.

# Fail on error for any line.
set -e

# Print the banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "DOWNLOADING OPENWRT SOURCE CODE"
>&2 echo "---------------------------------------------------------------------"

# Easier to reference the inside paths this way.
cd /INSIDE

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Clone the OpenWrt source code.
SOURCE_DIR="openwrt"
cd ~
if [ -e "${SOURCE_DIR}" ]
then
    rm -fr -- "${SOURCE_DIR}"
fi
git clone --progress "${REPO_URL}" "${SOURCE_DIR}" 2>&1
cd "${SOURCE_DIR}"

# If a code freeze is requested, go to that commit.
if [ -z ${REPO_COMMIT+x} ]
then
    echo "Using latest commit."
else
    echo "Freezing code to commit: ${REPO_COMMIT}"
    git reset --hard "${REPO_COMMIT}"
fi

# Download and install the feeds.
./scripts/feeds update -a 2>&1
./scripts/feeds install -a 2>&1

# Delete the git repository data.
# This saves over a hundred megabytes of data, plus it makes everything faster.
rm -fr .git/

# Make a tarfile with a cache of the original code.
# That way we don't need to checkout the repository again on each build.
if [ -e "${TAR_FILE}" ]
then
    rm -- "${TAR_FILE}"
fi
tar -caf "${TAR_FILE}" .
cd ..

# Delete the source code now. On each build it will be extracted from the tarfile.
rm -fr -- "${SOURCE_DIR}"


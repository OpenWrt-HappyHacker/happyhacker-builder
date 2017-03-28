#!/bin/bash
set -e

# Needed in some scenarios. Doesn't hurt when not needed.
cd /home/vagrant/

# Load the build configuration variables.
source /vagrant/script/config.sh

# Enable colors in the console.
if [ -e ".bashrc" ]; then
    sed -i s/\\#force_color_prompt\\=yes/force_color_prompt=yes/ .bashrc
fi

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

# Make a tarfile with a cache of the original code.
# That way we don't need to checkout the repository again on each build.
if [ -e "../${TAR_FILE}" ]
then
    rm -- "../${TAR_FILE}"
fi
tar -caf "../${TAR_FILE}" .
cd ..

# Delete the source code now. On each build it will be extracted from the tarfile.
rm -fr -- "${SOURCE_DIR}"


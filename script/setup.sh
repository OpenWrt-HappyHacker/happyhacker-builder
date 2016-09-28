#!/bin/bash

# Load the build configuration variables.
source /vagrant/script/config.sh

# Enable colors in the console.
sed -i s/\\#force_color_prompt\\=yes/force_color_prompt=yes/ .bashrc

# Clone the OpenWRT source code.
SOURCE_DIR="openwrt"
cd ~
if [ -e "${SOURCE_DIR}" ]
then
    rm -fr -- "${SOURCE_DIR}"
fi
git clone "${REPO_URL}" "${SOURCE_DIR}" 2>&1
cd "${SOURCE_DIR}"

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

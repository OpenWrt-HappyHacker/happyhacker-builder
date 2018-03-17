#!/bin/bash

# TODO: the work directory should have a randomized name.

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Set a variable with the directory with the profile-specific files and config.
PROFILE_DIR="/OUTSIDE/profiles/$1"

# Verify command line arguments.
case $# in
0)
    >&2 echo ""
    >&2 echo "Missing parameter: profile"
    >&2 echo "Available profiles:"
    for i in profiles/*/
    do
       i=$(echo "$i" | sed "s/^profiles//")
       i=${i::-1}
       >&2 echo "* $i"
    done
    >&2 echo ""
    exit 1
    ;;
1)
    if [ ! -e "${PROFILE_DIR}/config" ]
    then
        >&2 echo ""
        >&2 echo "Profile not found: $1"
        >&2 echo ""
        exit 1
    fi
    ;;
*)
    >&2 echo ""
    >&2 echo "Too many arguments"
    >&2 echo ""
    exit 1
esac

# Create the source directory where we will build the image, and switch to it.
mkdir -p "${BUILD_BASEDIR}/"
WORK_DIR="${BUILD_BASEDIR}/$1"
cd ~
if [ -e "${WORK_DIR}" ]
then
    rm -fr -- "${WORK_DIR}/"
fi
mkdir "${WORK_DIR}"
cd "${WORK_DIR}"

# Get the name of the source code cache.
SOURCE_ID=$(echo "${REPO_URL}"@"${REPO_COMMIT}" | md5sum | cut -d ' ' -f 1)
TAR_FILE="/OUTSIDE/bin/source-${SOURCE_ID}.tar.bz2"

# If the source code was already downloaded, use it.
if [ -f "${TAR_FILE}" ]
then
    echo "Fetching source code from cache..."
    tar -xaf "${TAR_FILE}"

# If not, download it from the git repository.
else
    echo "Downloading the source code from the repository..."

    # Clone the OpenWrt source code.
    git clone --progress "${REPO_URL}" . 2>&1

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
fi

# We already have the code, now let's customize it.
echo -e "Applying customizations...\n"

# Apply the OpenWrt patches.
if [ -e "${PROFILE_DIR}/patches" ]
then
    grep -v '^[ \t]*#' "${PROFILE_DIR}/patches" | grep -v '^[ \t]*$' | while read p
    do
        if [ -e "/OUTSIDE/patches/$p.patch" ]
        then
            git apply -v "/OUTSIDE/patches/$p.patch"
        fi
    done
fi

# Copy the makefile configuration for this profile.
if [ -e "${PROFILE_DIR}/config" ]
then
    cp "${PROFILE_DIR}/config" .config
else
    if [ -e "${PROFILE_DIR}/diffconfig" ]
    then
        cp "${PROFILE_DIR}/diffconfig" .config
    else
        echo "ERROR: missing configuration file"
        exit 1
    fi
fi

# Delete the temporary files.
# If we miss this step, sometimes the 'make' command behaves strangely.
if [ -e tmp/ ]
then
    rm -fr tmp/
    mkdir tmp
fi

# If it was a full configuration file, fix the makefile if it was generated
# using an older version of OpenWrt. If it was a differential configuration
# file, convert it to a full configuration file.
if [ -e "${PROFILE_DIR}/config" ]
then
    make oldconfig
else
    make defconfig
fi

# Launch the menuconfig.
make menuconfig

# Copy the full and differential configuration files outside the VM.
mkdir -p "/OUTSIDE/profiles/${PROFILE_NAME}"
cp .config "${PROFILE_DIR}/config"
./scripts/diffconfig.sh > "${PROFILE_DIR}/diffconfig"


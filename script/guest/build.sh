#!/bin/bash

#####
##
#
# The build script by building "profiles" that in turn may include "components". Each profile is a firmware build for a specific device and use case. Each
# component is a piece of software or configuration that defines a certain functionality. For example, you may have components to set up a Tor node and a file
# sharing webapp, and a profile for a specific compatible device that includes both components to make up a file sharing service over Tor.
#
# The files are laid out like this (all are optional unless specified):
#
#   bin/{profile}/*                       This is where the output files will be written
#   bin/builder-*.tar.bz2                 Cached precompiled binaries
#   bin/source-*.tar.bz2                  Cached OpenWrt source code
#
#   profiles/{profile}/config             OpenWrt makefile configuration, this is mandatory
#   profiles/{profile}/diffconfig         Differential configuration file, only used if config is missing
#   profiles/{profile}/components         List of components to be included in this profile
#   profiles/{profile}/patches            List of patches to be applied on this profile
#   profiles/{profile}/output             List of output files from the OpenWrt compilation to be obtained
#
#   profiles/{profile}/files/*            Files to be included directly in the device filesystem
#   profiles/{profile}/initialize.sh      Initialization script for this profile
#   profiles/{profile}/finish.sh          Post build customization script for this profile
#
#   components/{component}/files/*        Files to be included directly in the device filesystem
#   components/{component}/initialize.sh  Initialization script for this component
#   components/{component}/finish.sh      Post build customization script for this component
#
#   patches/{patch}.patch                 Git formatted patch for the OpenWrt source code to be applied
#
# The build script will begin by copying the OpenWrt makefile configuration into the VM. Then the components file is parsed to get the list of components. For
# each component, its files are copied into the VM as well to be included in the device filesystem. The order of the files is the same as the order in the
# list of components (this is important because if a file already exists, it will be overwritten). After that, the files meant to be included for the profile
# are copied as well. That means profiles can override files copied from components.
#
# After copying all the files, the patches are applied in the order specified by the patches file. This can come in handy when you need to modify the OpenWrt
# kernel to support specific hardware, or patch a bug that was not yet included in the OpenWrt official sources.
#
# When all patching is done, the scripts are run - first the initialization script for each component (again, in order) and finally the script for the profile
# itself. The point of the initialization scripts is to make changes to the files that for some reason may not be just included in the directory - for example,
# Git won't let you create empty directories, so you can fix that in the script. Another example would be the generation of SSL or Tor certificates, SSH keys,
# etc. that must be done on runtime and be different for each build.
#
# After the scripts are run, OpenWrt is compiled, and the output image files are placed in the bin directory. When the compilation is finished, the finish
# scripts are run - first the ones defined for each component (as always, in order) and finally the one for the profile. The purpose of the finish scripts is
# to customize the image files after compilation is done - for example you could generate secure hashes or do a cryptographic signature here.
#
##
#####

# TODO: the work directory should have a randomized name.

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Take the Epoch timestamp at the beginning of the build process.
# We will compare it later at the end of the build to see how long it took.
TIMESTAMP_START=$(date +%s.%N)

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# If the MAKE_JOBS argument is missing, use the number of cores instead.
if [ "${MAKE_JOBS}" == "" ]
then
    MAKE_JOBS=${NUM_CORES}
fi

# Set a variable with the directory with the profile-specific files and config.
PROFILE_DIR="/OUTSIDE/profiles/$1"

# Set a variable with the output directory.
OUTPUT_BASE_DIR="/OUTSIDE/bin/$1"
OUTPUT_UUID="$(uuidgen)"
OUTPUT_DIR="${OUTPUT_BASE_DIR}/${OUTPUT_UUID}"

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

# Print the banner.
>&2 echo "---------------------------------------------------------------------"
>&2 echo "BUILDING FIRMWARE IMAGE FOR PROFILE: $1"
>&2 echo "---------------------------------------------------------------------"

# Create the output directory where we will store all the files we build.
mkdir -p "${OUTPUT_DIR}/firmware"
mkdir -p "${OUTPUT_DIR}/keys"

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

# Get a hash of the compile configuration.
# This should encompass everything that, if changed, will force us to recompile.
BUILDER_ID=$(echo "${REPO_URL}"@"${REPO_COMMIT}" | cat "${PROFILE_DIR}/config" "${PROFILE_DIR}/patches" - | md5sum | cut -d ' ' -f 1)
echo "OpenWrt Builder ID: ${BUILDER_ID}"

# If the image generator was not compiled yet, compile it.
# This may take a very long time (about half an hour in a good laptop).
IMAGE_BUILDER="/OUTSIDE/bin/builder-${BUILDER_ID}.tar.bz2"
if [ -e "${IMAGE_BUILDER}" ]
then
    echo "Image generator found."
else
    echo "No image generator found, building from sources."

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

    # Store the configuration file we're effectively using.
    # This is useful for future reference.
    cp .config "${OUTPUT_DIR}/config"

    # Build OpenWrt.
    echo -e "\nCompiling the OpenWrt source code...\n"
    if (( ${VERBOSE} == 0 ))
    then
        make -j${MAKE_JOBS}
    else
        make -j1 V=s
    fi

    # We need to work around some of the problems with the image builder here.
    echo "Preparing the image builder..."

    # We will work in a temporary subdirectory.
    mkdir builder
    cd builder

    # Extract the OpenWrt image builder.
    tar -xaf "$(find ../bin -maxdepth 2 -name 'OpenWrt-ImageBuilder-*' -print -quit)"

    # Fix the path problem (we want a consistent directory structure).
    mv -- OpenWrt-ImageBuilder-*/{.[!.],}* .
    rmdir -- OpenWrt-ImageBuilder-*

    # Re-compress the image builder in a known location with a consistent filename.
    tar -cjf "${IMAGE_BUILDER}" .

    # Go back to the parent directory.
    cd ..

    # Delete all the build files.
    cd ..
    rm -fr -- "${WORK_DIR}/"
    mkdir "${WORK_DIR}"
    cd "${WORK_DIR}"
fi

# Just some paranoid programming...
if ! [ -e "${IMAGE_BUILDER}" ]
then
    >&2 echo "INTERNAL ERROR"
    exit 1
fi

# Extract the image generator.
echo "Extracting image generator..."
tar -xaf "${IMAGE_BUILDER}"
echo -e "Applying customizations...\n"

# Copy the custom files for each component.
if [ -e "${PROFILE_DIR}/components" ]
then
    while read src
    do
        COMPONENT_DIR="/OUTSIDE/components/$src"
        if [ -e "${COMPONENT_DIR}/files/" ]
        then
            cp -rvT "${COMPONENT_DIR}/files/" ./files/
        fi
    done < "${PROFILE_DIR}/components"
fi

# Copy the custom files for this profile.
if [ -e "${PROFILE_DIR}/files/" ]
then
    cp -rvT "${PROFILE_DIR}/files/" ./files/
fi

# Delete the temporary files.
# If we miss this step, sometimes make behaves strangely.
if [ -e tmp/ ]
then
    rm -fr tmp/
    mkdir tmp
fi

# Run the per-component initialization scripts.
if [ -e "${PROFILE_DIR}/components" ]
then
    grep -v '^[ \t]*#' "${PROFILE_DIR}/components" | grep -v '^[ \t]*$' | while read src
    do
        COMPONENT_DIR="/OUTSIDE/components/$src"
        if [ -e "${COMPONENT_DIR}/initialize.sh" ]
        then
            PRESERVE_DIR=$(pwd)
            source "${COMPONENT_DIR}/initialize.sh"
            cd "${PRESERVE_DIR}"
        fi
    done
fi

# Run the per-profile initialization script.
if [ -e "${PROFILE_DIR}/initialize.sh" ]
then
    PRESERVE_DIR=$(pwd)
    source "${PROFILE_DIR}/initialize.sh"
    cd "${PRESERVE_DIR}"
fi

# Create the image with the target profile we selected in the config file.
# We don't have parallelization or verbosity control anymore.
# Also, the image builder is so dumb it won't remember the profile and packages
# we used when building, so we need to recreate all that ourselves.
# Furthermore, the packages we have built may not even match those of the profile.
# We can't use the official repo over the internet either (that's the OpenWrt wiki "fix").
# (Sorry for being such a hater, but... waaaay too much time wasted on this kinda crap...)
echo -e "\nCreating image...\n"
make info > make_info.txt
bash -c "$(/OUTSIDE/script/guest/get_openwrt_image_builder_command_line.py)"

# Copy the output files to the output directory.
if [ -e "${PROFILE_DIR}/output" ]
then
    grep -v '^[ \t]*#' "${PROFILE_DIR}/output" | grep -v '^[ \t]*$' | while read src
    do
        # No double quotes here - we want glob expressions to be interpreted.
        cp -r -- bin/*/$src "${OUTPUT_DIR}/firmware"
    done
else
    cp -r -- bin/*/* "${OUTPUT_DIR}/firmware"
fi

# Copy the logs to the output directory.
if [ -e logs/ ]
then
    cp -r logs/ "${OUTPUT_DIR}/"
fi

# Copy the makefile with some utility commands.
cp /OUTSIDE/script/data/Makefile.build "${OUTPUT_DIR}/Makefile"

# Run the after build scripts for each component.
# The OUTPUT_DIR variable has the pathname of the output directory.
if [ -e "${PROFILE_DIR}/components" ]
then
    grep -v '^[ \t]*#' "${PROFILE_DIR}/components" | grep -v '^[ \t]*$' | while read src
    do
        COMPONENT_DIR="/OUTSIDE/components/$src"
        if [ -e "${COMPONENT_DIR}/finalize.sh" ]
        then
            PRESERVE_DIR=$(pwd)
            source "${COMPONENT_DIR}/finalize.sh"
            cd "${PRESERVE_DIR}"
        fi
    done
fi

# Run the after build script for this profile.
# The OUTPUT_DIR variable has the pathname of the output directory.
if [ -e "${PROFILE_DIR}/finalize.sh" ]
then
    PRESERVE_DIR=$(pwd)
    source "${PROFILE_DIR}/finalize.sh"
    cd "${PRESERVE_DIR}"
fi

# Delete all of the build files now that we're done.
# Note that for failed builds all those files will still be there.
# This is useful for debugging.
echo "Clearing up the temporary files..."
cd ..
rm -fr -- "${WORK_DIR}"

# Calculate how long did the build take and tell the user.
TIMESTAMP_END=$(date +%s.%N)
DELTA_TIME=$(echo "${TIMESTAMP_END} - ${TIMESTAMP_START}" | bc)
DELTA_TIME_FORMATTED=$(date -u -d @0${DELTA_TIME} +"%T")
>&2 echo -e "\n---------------------------------------------------------------------"
>&2 echo "DONE"
>&2 echo "---------------------------------------------------------------------"
>&2 echo -e "\nBuild finished."
>&2 echo "Output files stored in: bin/$1/${OUTPUT_UUID}"
>&2 echo "Build time: ${DELTA_TIME_FORMATTED} (${DELTA_TIME} seconds)."


#!/bin/bash

#####
##
#
# The build script by building "profiles" that in turn may include "components". Each profile is a firmware build for a specific device and use case. Each
# component is a piece of software or configuration that defines a certain functionality. For example, you may have components to set up a Tor node and a file
# sharing webapp, and a profile for a specific compatible device that includes both components to make up a file sharing service over Tor.
#
# The files are laid out like this:
#
#   bin/{profile}/*                       This is where the output files will be written
#
#   profiles/{profile}/config             OpenWrt makefile configuration, this is mandatory
#   profiles/{profile}/diffconfig         Differential configuration file, only used if config is missing
#   profiles/{profile}/components         List of components to be included in this profile
#   profiles/{profile}/patches            List of patches to be applied on this profile
#
#   profiles/{profile}/files/*            Files to be included directly in the device filesystem
#   profiles/{profile}/initialize.sh      Initialization script for this profile
#   profiles/{profile}/finish.sh          Post build customization script for this profile
#
#   components/{component}/files/*        Files to be included directly in the device filesystem
#   components/{component}/initialize.sh  Initialization script for this component
#   components/{component}/finish.sh      Post build customization script for this component
#
#   patches/{patch}.diff                  Diff-style patch for the OpenWrt source code to be applied
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
# As a final step, the files in the bin directory are copied outside of the VM into the corresponding location for this profile.
#
##
#####

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

# Create the source directory where we will build the image, and switch to it.
mkdir -p "${BUILD_BASEDIR}/"
SOURCE_DIR="${BUILD_BASEDIR}/$1"
cd ~
if [ -e "${SOURCE_DIR}" ]
then
    rm -fr -- "${SOURCE_DIR}/"
fi
mkdir "${SOURCE_DIR}"
cd "${SOURCE_DIR}"

# If there is a pre-compiled image generator, use it.
IMAGE_BUILDER="${OUTPUT_BASE_DIR}/builder.tar.bz2"
if [ -e "${IMAGE_BUILDER}" ]
then
    echo "Image generator found at: ${IMAGE_BUILDER}"

    # Extract the image generator.
    echo "Extracting image generator..."
    tar -xaf "${IMAGE_BUILDER}"
    echo -e "Applying customizations...\n"

# If there is no pre-compiled generator, build from sources.
else
    echo "No image generator found, building from sources."

    # Get the OpenWrt source code.
    echo "Fetching source code from cache..."
    tar -xaf "${TAR_FILE}"
    echo -e "Applying customizations...\n"

    # Apply the OpenWrt patches.
    if [ -e "${PROFILE_DIR}/patches" ]
    then
        while read p
        do
            if [ -e "/OUTSIDE/patches/$p.diff" ]
            then
                git apply -v "/OUTSIDE/patches/$p.diff"
            fi
        done < "${PROFILE_DIR}/patches"
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
fi

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
    while read src
    do
        COMPONENT_DIR="/OUTSIDE/components/$src"
        if [ -e "${COMPONENT_DIR}/initialize.sh" ]
        then
            source "${COMPONENT_DIR}/initialize.sh"
        fi
    done < "${PROFILE_DIR}/components"
fi

# Run the per-profile initialization script.
if [ -e "${PROFILE_DIR}/initialize.sh" ]
then
    source "${PROFILE_DIR}/initialize.sh"
fi

# If building with the image generator...
if [ -e "${IMAGE_BUILDER}" ]
then

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

# If building from sources...
else

    # If it was a full configuration file, fix the makefile if it was generated
    # using an older version of OpenWrt. If it was a differential configuration
    # file, convert it to a full configuration file.
    if [ -e "${PROFILE_DIR}/config" ]
    then
        make oldconfig
    else
        make defconfig
    fi

    # Build OpenWrt.
    echo -e "\nCompiling...\n"
    if (( ${VERBOSE} == 0 ))
    then
        make -j${MAKE_JOBS}
    else
        make -j1 V=s
    fi
fi

# Copy the output and logs to the vagrant synced directory.
# This is done before the finalization scripts to simplify things.
# However, if the finalization scripts fail we may have deleted a
# previous successful build... but this is an acceptable edge case.
if [ -e bin ] && [ $(find bin/ -maxdepth 1 -type d -printf 1 | wc -m) -eq 2 ]
then
    rm -fr -- "${OUTPUT_DIR}/"
    mkdir -p "${OUTPUT_BASE_DIR}"
    cp -r bin/*/ "${OUTPUT_DIR}/"
    if [ -e logs/ ]
    then
        cp -r logs/ "${OUTPUT_DIR}/"
    fi
    cp .config "${OUTPUT_DIR}/config"
else
    mkdir -p "${OUTPUT_DIR}/"
    cp .config "${OUTPUT_DIR}/config"
    if [ -e logs/ ]
    then
        rm -fr -- "${OUTPUT_DIR}/logs/"
        cp -r logs/ "${OUTPUT_DIR}/"
    fi
fi
>&2 echo -e "\nBuild finished."
>&2 echo "Output files stored in: bin/$1/${OUTPUT_UUID}"

# Run the after build scripts for each component.
# The 
# The OUTPUT_DIR variable has the pathname of the output directory.
if [ -e "${PROFILE_DIR}/components" ]
then
    while read src
    do
        COMPONENT_DIR="/OUTSIDE/components/$src"
        if [ -e "${COMPONENT_DIR}/finalize.sh" ]
        then
            source "${COMPONENT_DIR}/finalize.sh"
        fi
    done < "${PROFILE_DIR}/components"
fi

# Run the after build script for this profile.
# The OUTPUT_DIR variable has the pathname of the output directory.
if [ -e "${PROFILE_DIR}/finalize.sh" ]
then
    source "${PROFILE_DIR}/finalize.sh"
fi

# If there is no image builder, copy the one we just built.
# We need to work around some of the problems with the image builder here.
if [ ! -e "${IMAGE_BUILDER}" ]
then
    echo "Preparing the image builder..."

    # We will work in a temporary subdirectory.
    mkdir builder
    cd builder

    # Extract the OpenWrt image builder.
    tar -xaf "$(find ${OUTPUT_DIR} -maxdepth 1 -name 'OpenWrt-ImageBuilder-*' -print -quit)"

    # Fix the path problem (we want a consistent directory structure).
    mv -- OpenWrt-ImageBuilder-*/{.[!.],}* .
    rmdir -- OpenWrt-ImageBuilder-*

    # We could copy the script generated files here too...
    # But let's not do that, since the image builder won't work on its own anyway.
    # Also we don't want anyone to create firmware images with duplicated keys.
    # In the future we may want to bundle some of our scripts here for optional standalone usage.
    #cp -r ../files .

    # Re-compress the image builder inn a known location with a consistent filename.
    tar -cjf "${OUTPUT_BASE_DIR}/builder.tar.bz2" .

    # Go back to the parent directory.
    cd ..

    # No need to delete the temporary directory, since that's done immediately after this code.
    #rm -fr builder
fi

# Delete all of the build files in the VM. This is needed to
# free some disk space, otherwise the HD fills up too quickly
# and builds begin to fail.
echo "Clearing up the temporary files..."
cd ~
rm -fr -- "${SOURCE_DIR}"

# Calculate how long did the build take and tell the user.
TIMESTAMP_END=$(date +%s.%N)
DELTA_TIME=$(echo "${TIMESTAMP_END} - ${TIMESTAMP_START}" | bc)
DELTA_TIME_FORMATTED=$(date -u -d @0${DELTA_TIME} +"%T")
>&2 echo "Build time: ${DELTA_TIME_FORMATTED} (${DELTA_TIME} seconds)."

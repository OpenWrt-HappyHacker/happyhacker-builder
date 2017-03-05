#!/bin/bash

#####
##
#
# The build script by building "targets" that in turn may include "components". Each target is a firmware build for a specific device and use case. Each
# component is a piece of software or configuration that defines a certain functionality. For example, you may have components to set up a Tor node and a file
# sharing webapp, and a target for a specific compatible device that includes both sources to make up a file sharing service over Tor.
#
# The files are laid out like this:
#
#   bin/{target}/*                      This is where the output files will be written
#
#   config/{target}/config              OpenWrt makefile configuration, this is mandatory
#   config/{target}/diffconfig          Differential configuration file, only used if config is missing
#   config/{target}/sources             List of components to be included in this target
#   config/{target}/patches             List of patches to be applied on this target
#
#   config/{target}/files/*             Files to be included directly in the device filesystem
#   config/{target}/initialize.sh       Initialization script for this target
#   config/{target}/finish.sh           Post build customization script for this target
#
#   src/{component}/files/*             Files to be included directly in the device filesystem
#   src/{component}/initialize.sh       Initialization script for this component
#   src/{component}/finish.sh           Post build customization script for this component
#
#   patches/{patch}.diff                Diff-style patch for the OpenWrt source code to be applied
#
# The build script will begin by copying the OpenWrt makefile configuration into the VM. Then the sources file is parsed to get the list of components. For
# each component, its files are copied into the VM as well to be included in the device filesystem. The order of the files is the same as the order in the
# list of sources (this is important because if a file already exists, it will be overwritten). After that, the files meant to be included for the target are
# copied as well.
#
# After copying all the files, the patches are applied in the order specified by the patches file. This can come in handy when you need to modify the OpenWrt
# kernel to support specific hardware, or patch a bug that was not yet included in the OpenWrt official sources.
#
# When all patching is done, the scripts are run - first the initialization script for each component (again, in order) and finally the script for the target
# itself. The point of the initialization scripts is to make changes to the files that for some reason may not be just included in the directory - for example,
# Git won't let you create empty directories, so you can fix that in the script. Another example would be the generation of SSL or Tor certificates, SSH keys,
# etc. that must be done on runtime and be different for each build.
#
# Note that the copying of files, applying of patches and execution of scripts happen only for new builds. If you do a rebuild instead, none of this happens.
#
# After the scripts are run, OpenWrt is compiled, and the target image files are placed in the bin directory. When the compilation is finished, the finish
# scripts are run - first the ones defined for each component (as always, in order) and finally the one for the target. The purpose of the finish scripts is
# to customize the image files after compilation is done - for example you could generate secure hashes or do a cryptographic signature here. These scripts are
# run regardless of whether it's a new build or a rebuild.
#
# As a final step, the files in the bin directory are copied outside of the VM into the corresponding location for this target.
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
source /vagrant/script/config.sh

# If the MAKE_JOBS argument is missing, use the number of cores instead.
if [ "${MAKE_JOBS}" == "" ]
then
    MAKE_JOBS=${NUM_CORES}
fi

# Verify command line arguments.
case $# in
0)
    >&2 echo ""
    >&2 echo "Missing parameter: build target"
    >&2 echo "Available targets:"
    for i in config/*/
    do
       i=$(echo "$i" | sed "s/^config//")
       i=${i::-1}
       >&2 echo "* $i"
    done
    >&2 echo ""
    exit 1
    ;;
1)
    if [ ! -e "/vagrant/config/$1/config" ]
    then
        >&2 echo ""
        >&2 echo "Invalid build target: $1"
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
>&2 echo "BUILDING FIRMWARE IMAGE FOR TARGET: $1"
>&2 echo "---------------------------------------------------------------------"

# Get the OpenWrt source code.
SOURCE_DIR="$1"
cd ~
if [ -e "${SOURCE_DIR}" ]
then
    rm -fr -- "${SOURCE_DIR}/"
fi
mkdir "${SOURCE_DIR}"
cd "${SOURCE_DIR}"
tar -xaf "../${TAR_FILE}"

# Copy the makefile configuration and custom files for the desired target.
if [ -e "/vagrant/config/$1/config" ]
then
    cp "/vagrant/config/$1/config" .config
else
    if [ -e "/vagrant/config/$1/diffconfig" ]
    then
        cp "/vagrant/config/$1/diffconfig" .config
    else
        echo "ERROR: missing configuration file"
        exit 1
    fi
fi

# Copy the custom files for each component.
if [ -e "/vagrant/config/$1/sources" ]
then
    while read src
    do
        if [ -e "/vagrant/src/$src/files/" ]
        then
            cp -rvT "/vagrant/src/$src/files/" ./files/
        fi
    done < "/vagrant/config/$1/sources"
fi

# Copy the custom files for this target.
if [ -e "/vagrant/config/$1/files/" ]
then
    cp -rvT "/vagrant/config/$1/files/" ./files/
fi

# Apply the OpenWrt patches.
if [ -e "/vagrant/config/$1/patches" ]
then
    while read p
    do
        if [ -e "/vagrant/patches/$p.diff" ]
        then
            git apply -v "/vagrant/patches/$p.diff"
        fi
    done < "/vagrant/config/$1/patches"
fi

# Delete the temporary files.
# If we miss this step, sometimes make behaves strangely.
if [ -e tmp/ ]
then
    rm -fr tmp/
    mkdir tmp
fi

# Run the per-component initialization scripts.
if [ -e "/vagrant/config/$1/sources" ]
then
    while read src
    do
        if [ -e "/vagrant/src/$src/initialize.sh" ]
        then
            source "/vagrant/src/$src/initialize.sh"
        fi
    done < "/vagrant/config/$1/sources"
fi

# Run the per-target initialization script.
if [ -e "/vagrant/config/$1/initialize.sh" ]
then
    source "/vagrant/config/$1/initialize.sh"
fi

# If it was a full configuration file, fix the makefile if it was generated
# using an older version of OpenWrt. If it was a differential configuration
# file, convert it to a full configuration file.
if [ -e "/vagrant/config/$1/config" ]
then
    make oldconfig
else
    make defconfig
fi

# Build OpenWrt.
if (( ${VERBOSE} == 0 ))
then
    make -j${MAKE_JOBS}
else
    make -j1 V=s
fi

# Run the after build scripts for each component.
if [ -e "/vagrant/config/$1/sources" ]
then
    while read src
    do
        if [ -e "/vagrant/src/$src/finish.sh" ]
        then
            source "/vagrant/src/$src/finish.sh"
        fi
    done < "/vagrant/config/$1/sources"
fi

# Run the after build script for this target.
if [ -e "/vagrant/config/$1/finish.sh" ]
then
    source "/vagrant/config/$1/finish.sh"
fi

# Copy the output and logs to the vagrant synced directory.
if [ -e bin ] && [ $(find bin/ -maxdepth 1 -type d -printf 1 | wc -m) -eq 2 ]
then
    rm -fr -- "/vagrant/bin/$1/"
    cp -r bin/*/ "/vagrant/bin/$1/"
    if [ -e logs/ ]
    then
        cp -r logs/ "/vagrant/bin/$1/"
    fi
    >&2 echo "Build successful, output files stored in: bin/$1"
else
    if [ -e logs/ ]
    then
        mkdir -p "/vagrant/bin/$1/"
        cp -r logs/ "/vagrant/bin/$1/"
        >&2 echo "Build FAILED, log files stored in: bin/$1/logs"
    else
        >&2 echo "Build FAILED, no log files found either"
    fi
fi

# If and only if the build was successfuly up to this point,
# delete all of the build files in the VM. This is needed to
# free some disk space, otherwise the HD fills up too quickly
# and builds begin to fail.
echo "Clearing up the VM hard drive..."
cd ~
rm -fr -- "${SOURCE_DIR}"

# Calculate how long did the build take and tell the user.
TIMESTAMP_END=$(date +%s.%N)
DELTA_TIME=$(echo "${TIMESTAMP_END} - ${TIMESTAMP_START}" | bc)
DELTA_TIME_FORMATTED=$(date -u -d @0${DELTA_TIME} +"%T")
>&2 echo "Build time: ${DELTA_TIME_FORMATTED} (${DELTA_TIME} seconds)."


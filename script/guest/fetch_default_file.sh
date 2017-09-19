#!/bin/bash

# This script prepares to modify a default OpenWrt file.
# The first argument is the name of the package that contains the file.
# The second argument is the path to the desired file as it would be on the device.
#
# For example, to fetch the original contents of the shadow file, you do:
#   /OUTSIDE/script/guest/fetch_default_file.sh base-files /etc/shadow
#
# The idea here is to make sure we have a copy of the default contents for a certain
# file in the files/ folder, so we can make changes to it there, without having to
# hardcode such a file in our build system. This gives us forward compatibility with
# whatever changes OpenWrt devs make.

# Set the error mode to fail on any command.
set -e

# Check the command line arguments.
if (( $# < 2 ))
then
    >&2 echo "Error: not enough arguments provided"
    exit 1
fi
if (( $# > 2 ))
then
    >&2 echo "Error: too many arguments provided"
    exit 1
fi

# If the file already exists, do nothing, we're done.
# Typically this will be the case if this script is invoked more than once.
if [ -e "./files/$2" ]
then
    exit 0
fi

# Get the directory where we will want to copy the file.
# Make sure the directory exists.
# We need an absolute path because we will be switching directory soon.
TARGET_PATHNAME=$(dirname "./files/$2")
mkdir -p "${TARGET_PATHNAME}"
TARGET_PATHNAME=$(realpath "${TARGET_PATHNAME}")

# The base files will be packaged.
# We need to extract the files from the .ipk archive.
FOUND=0
for CATEGORY in ./packages/*/
do
    IPK_FILE=$(realpath ${CATEGORY}/$1_*.ipk)
    if [ -e "${IPK_FILE}" ]
    then
        FOUND=1
        break
    fi
done
if [ $FOUND -eq 0 ]
then
    >&2 echo "ERROR: Could not find device file: $1:$2"
    exit 1
fi

# Create a temporary directory for us to work with.
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
pushd "${TMP_DIR}" > /dev/null

# Unpack the .ipk archive.
tar zxpf "${IPK_FILE}"

# Unpack the data files.
tar xzf data.tar.gz

# Copy the requested file.
cp "./$2" "${TARGET_PATHNAME}/"

# Delete the temporary files.
popd > /dev/null
rm -fr -- "${TMP_DIR}"


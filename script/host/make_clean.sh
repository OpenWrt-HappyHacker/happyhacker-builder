#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Ask the user for confirmation.
echo "WARNING: This is a dangerous operation!"
echo "The SSH keys for your devices will be lost!"
while true; do
    read -p "Are you sure? (yes|no) " yn
    case $yn in
        yes) break;;
        no) echo "Aborted."; exit 1;;
        *) echo "Please answer yes or no.";;
    esac
done

# Delete the build subdirectories for each target, but DO NOT DELETE the image
# builders. We don't want to have to recompile everything each time.
# Use the make destroy command to delete everything in the bin directory.
rm -fr ./bin/*/*/

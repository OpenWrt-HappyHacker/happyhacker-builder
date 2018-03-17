#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Run different commands depending on the sandbox provider.
case "${SANDBOX_PROVIDER}" in

# When not using a sandbox.
none)
  # No-op
  ;;

# Halt the Vagrant VM.
vagrant)
  vagrant halt
  ;;

# Stop the LXD container.
lxd)
  if [[ $(lxc info happyhacker-lxd 2> /dev/null | grep ^Status:\ .*\$ | sed "s/^Status: \(.*\)\$/\\1/" | grep -F Stopped | wc -c) = 0 ]]
  then
    echo "Stopping the container..."
    lxc stop "${LXD_CONTAINER_NAME}"
  fi
  ;;

# Stop the Docker container.
docker)
  docker stop $CNT_NM
  ;;

# Remind the user to configure the build system.
error)
  echo "You must create a config/user.yml file before using the builder."
  exit 1
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


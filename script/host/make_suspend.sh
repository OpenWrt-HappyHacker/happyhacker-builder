#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Run different commands depending on the sandbox provider.
case "${SANDBOX_PROVIDER}" in

# Destroy the Vagrant VM.
vagrant)
  vagrant destroy
  ;;

# Stop and remove the Docker container.
docker)
  docker stop $CNT_NM
  docker rm $CNT_NM
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


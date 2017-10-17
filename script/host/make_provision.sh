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
  # The "host" is the "guest" now.
  sudo ./script/host/prov-no-sandbox.sh $(id -un) $(id -gn)
  ;;

# When using Vagrant.
vagrant)
  vagrant provision
  ;;

# When using LXD.
lxd)
  lxc exec "${LXD_CONTAINER_NAME}" /OUTSIDE/script/guest/prov-lxd.sh
  ;;

# When using Docker.
docker)
  # TODO
  echo "Unsupported operation."
  exit 1
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


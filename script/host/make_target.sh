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
  mkdir -p build
  pushd build > /dev/null
  ../script/guest/build.sh $1
  popd > /dev/null
  ;;

# When using Vagrant.
vagrant)
  vagrant ssh -c "/OUTSIDE/script/guest/build.sh \"$1\""
  ;;

# When using LXD.
lxd)
  lxc exec "${LXD_CONTAINER_NAME}" -- su "${LXD_INSIDE_USER}" -c "/OUTSIDE/script/guest/build.sh \"$1\""
  ;;

# When using Docker.
docker)
  sudo docker exec -it $CNT_NM su $_user -c sh -c "/OUTSIDE/script/guest/build.sh \"$1\""
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


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
  source ./script/host/lxd_sync_host_to_guest.sh
  lxc exec "${LXD_CONTAINER_NAME}" -- su "${LXD_INSIDE_USER}" -c "/OUTSIDE/script/guest/build.sh \"$1\""
  TARGET="$1"
  source ./script/host/lxd_sync_guest_to_host.sh
  ;;

# When using Docker.
docker)

  # Make sure the write permissions for the container are correct.
  # ./script must be written to as it contains the CA keys.
  # ./bin will contain the build output.
  chmod 777 ./script
  chmod 777 ./bin
  chmod 777 $(find ./bin -type d)

  ssh -oStrictHostKeyChecking=no vagrant@127.0.0.1 -p 22222 -i ./script/data/builder-keys/ssh.priv /vagrant/script/guest/build.sh \"$1\"
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


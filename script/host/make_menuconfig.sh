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
  ../script/guest/menuconfig.sh $1
  popd > /dev/null
  ;;

# When using Vagrant.
vagrant)
  vagrant ssh -c "/OUTSIDE/script/guest/menuconfig.sh \"$1\""
  ;;

# When using LXD.
lxd)

  # Synchronize the shared folders, host to guest.
  source ./script/host/lxd_sync_host_to_guest.sh

  # Run the menuconfig script.
  lxc exec "${LXD_CONTAINER_NAME}" -- su "${LXD_INSIDE_USER}" -c "/OUTSIDE/script/guest/menuconfig.sh \"$1\""

  # Synchronize the shared folders, guest to host.
  source ./script/host/lxd_sync_guest_to_host.sh

  ;;

# When using Docker.
docker)
  ssh -oStrictHostKeyChecking=no vagrant@127.0.0.1 -p 22222 -i ./script/builder-keys/ssh.priv /vagrant/script/guest/menuconfig.sh \"$1\"
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


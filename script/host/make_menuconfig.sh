#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Check the command line arguments.
if (( $# < 1 ))
then
    >&2 echo "Error: missing profile name"
    >&2 echo
    >&2 echo "Usage:"
    >&2 echo "  make menuconfig CONFIG=<profile>"
    >&2 echo
    exit 1
fi
if (( $# > 1 ))
then
    >&2 echo "Error: too many arguments provided"
    exit 1
fi

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
  lxc exec "${LXD_CONTAINER_NAME}" -- su "${LXD_INSIDE_USER}" -c "/OUTSIDE/script/guest/menuconfig.sh \"$1\""
  ;;

# When using Docker.
docker)
  ssh -oStrictHostKeyChecking=no vagrant@127.0.0.1 -p 22222 -i ./script/builder-keys/ssh.priv /vagrant/script/guest/menuconfig.sh \"$1\"
  ;;

# Remind the user to configure the build system.
error)
  echo "You must create a config/user.ymlfile before using the builder."
  exit 1
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


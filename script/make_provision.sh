#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Run different commands depending on the sandbox provider.
case "${SANDBOX_PROVIDER}" in

# When using Vagrant.
vagrant)
  vagrant provision
  ;;

# When using Docker.
docker)
  ssh -oStrictHostKeyChecking=no vagrant@127.0.0.1 -p 22222 -i ./script/builder-keys/ssh.priv /vagrant/script/prov-tor.sh
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


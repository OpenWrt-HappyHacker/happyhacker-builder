#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Run different commands depending on the sandbox provider.
case "${SANDBOX_PROVIDER}" in

#-----------------------------------------------------------------------------
# When using Vagrant.
vagrant)
  vagrant up
  ;;

#-----------------------------------------------------------------------------
# When using Docker.
docker)

  # TODO: Dynamics volumen share source, now it's static /DinD/vagrant-happyhacker
  # TODO: Clean status eror when container is not created
  # TODO: When finish scripts modifications, uncomment next line breaks cache image and rebuild it everytime

  # If not it's running, run it
  status=$(docker inspect --format='{{ .State.Status }}' $CNT_NM)
  if ! [ "$status" == "running"  ]; then
  docker run  --privileged \
            -e "container=docker" \
            -e "TERM=xterm-256color" \
            -p 22222:22 \
            --hostname $CNT_NM \
            --name $CNT_NM \
            -v /DinD/vagrant-happyhacker:/vagrant \
            -d $CNT_TP
  fi

  ;;

#-----------------------------------------------------------------------------
*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


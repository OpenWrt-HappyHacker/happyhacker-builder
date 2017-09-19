#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Run different commands depending on the sandbox provider.
case "${SANDBOX_PROVIDER}" in

#-----------------------------------------------------------------------------
# When not using a sandbox.
none)
  # The "host" is the "guest" now.
  if ! [ -e /OUTSIDE/.provisioned ]
  then
    sudo ./script/guest/prov-no-sandbox.sh $(id -un) $(id -gn)
  fi
  ;;

#-----------------------------------------------------------------------------
# When using Vagrant.
vagrant)
  command -v foo >/dev/null 2>&1 || { echo >&2 "The 'vagrant' command is required but not installed. Aborting..."; exit 1; }
  vagrant up
  ;;

#-----------------------------------------------------------------------------
# When using LXD.
lxd)
  command -v lxd >/dev/null 2>&1 || { echo >&2 "The 'lxd' command is required but not installed. Aborting..."; exit 1; }
  command -v bindfs >/dev/null 2>&1 || { echo >&2 "The 'bindfs' command is required but not installed. Aborting..."; exit 1; }
  source ./script/host/lxd_up.sh
  ;;

#-----------------------------------------------------------------------------
# When using Docker.
docker)
  command -v docker >/dev/null 2>&1 || { echo >&2 "The 'docker' command is required but not installed. Aborting..."; exit 1; }

  # Make sure the Docker service is running.
  sudo systemctl start docker

  # If the container is not running...
  if [ ! "$(sudo docker ps -q -f name=${CNT_NM})" ]
  then

     # If the container does not exist...
    if [ ! "$(sudo docker ps -aq -f name=${CNT_NM})" ]
    then

        # Create the container.
        script/host/docker_create_container.sh

    else

        # If it exists, start it.
        sudo docker start $CNT_NM
    fi
  fi
  ;;

#-----------------------------------------------------------------------------
*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


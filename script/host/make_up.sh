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

  # Fix the SSH key permissions, because Git does not preserve them.
  chmod 400 -- ./script/data/builder-keys/*

  # Create the base image if it doesn't exist.
  if [[ "$(docker images -q $CNT_TP 2> /dev/null)" == "" ]]
  then
    docker build -t $CNT_TP .
  fi

  # If not it's running, run it.
  if [ ! "$(docker ps -q -f name=${CNT_NM})" ] || [ ! "$(docker ps -aq -f status=running -f name=${CNT_NM})" ]
  then
    docker run --privileged \
               -e "container=docker" \
               -e "TERM=xterm-256color" \
               -p 22222:22 \
               --hostname $CNT_NM \
               --name $CNT_NM \
               -v /DinD/vagrant-happyhacker:/vagrant \
               -d $CNT_TP

  # Restart sshd
  docker exec $CNT_NM systemctl restart sshd
  fi

  ;;

#-----------------------------------------------------------------------------
*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


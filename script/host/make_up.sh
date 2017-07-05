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
  vagrant up
  ;;

#-----------------------------------------------------------------------------
# When using LXD.
lxd)

  # If the container does not exist, create it.
  if [[ $(lxc info "${LXD_CONTAINER_NAME}" 2> /dev/null | wc -c) = 0 ]]
  then
    echo "Creating the container..."
    lxc launch "${LXD_REMOTE_IMAGE}" "${LXD_CONTAINER_NAME}"
  fi

  # If the network does not exist, create it.
  if [[ $(lxc network show "${LXD_NETWORK_NAME}" 2> /dev/null | wc -c) = 0 ]]
  then
    echo "Creating the network..."
    lxc network create "${LXD_NETWORK_NAME}"
  fi

  # If the network was not attached to our container, attach it.
  if [[ $(lxc network show "${LXD_NETWORK_NAME}" | sed '0,/usedby/d' | rev | cut -d "/" -f1 | rev | grep -Fx "${LXD_CONTAINER_NAME}" | wc -c) = 0 ]]
  then
    echo "Attaching the network to the container..."
    lxc network attach "${LXD_NETWORK_NAME}" "${LXD_CONTAINER_NAME}"
  fi

  # If the container was not running, start it.
  if [[ $(lxc info "${LXD_CONTAINER_NAME}" | grep ^Status:\ .*\$ | sed "s/^Status: \(.*\)\$/\\1/" | grep -F Running | wc -c) = 0 ]]
  then
    echo "Starting the container..."
    lxc start "${LXD_CONTAINER_NAME}"
  fi

  # If the container has not been provisioned, provision it.
  if [[ $(lxc exec "${LXD_CONTAINER_NAME}" -- bash -c "if [ -e /.provisioned ] ; then echo 1; else echo 0; fi") = 0 ]]
  then
    echo "Provisioning the container..."
    source ./script/host/lxd_sync_host_to_guest.sh
    lxc exec "${LXD_CONTAINER_NAME}" bash /OUTSIDE/script/guest/prov-lxd.sh
  fi

  ;;

#-----------------------------------------------------------------------------
# When using Docker.
docker)

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


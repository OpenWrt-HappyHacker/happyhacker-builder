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
  bash
  ;;

# When using Vagrant.
vagrant)
  vagrant ssh
  ;;

# When using LXD.
lxd)
  lxc exec "${LXD_CONTAINER_NAME}" -- su "${LXD_INSIDE_USER}" -c "cd; bash; true"
  ;;

# When using Docker.
docker)

  # Load the common container functions.
  source script/host/container_common_functions.sh

  # TODO: Add ssh support
  ## TODO: Check output ssh command and only in case of error reprovision ssh public key
  #prov_sshpubkey $CNT_NM vagrant ./script/data/builder-keys/ssh.pub /home/vagrant/.ssh/authorized_keys
  #ssh -oStrictHostKeyChecking=no vagrant@127.0.0.1 -p 22222 -i ./script/data/builder-keys/ssh.priv
  RRUN $_cnt_nm 'sh'
  ;;

# Remind the user to configure the build system.
error)
  echo "You must edit the script/config.sh file before using the builder."
  exit 1
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


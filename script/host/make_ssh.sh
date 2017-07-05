#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# Load the build configuration variables.
source script/config.sh

# Provision ssh public keys to a local docker container
function prov_sshpubkey {
#   $1 --> Container name
#   $2 --> Container username
#   $3 --> src: SSH public key
#   $4 --> dest: authorized_keys

# TODO: Detect empty $4 and set default path /home/$2/.ssh/authorized_keys, before check $2 is not root
# TODO: Use expect, to provide key to remote container using ssh-copy-id with password in first run.
# TODO: Use default key, to provide to remote container using ssh-copy-id in first run.


    _cnt_nm=$1
    _cnt_user=$2
    _pth_sshpubkey=$3
    _fn_sshpubkey=$(basename $3)
    _pth_authkeysfile=$4

    docker cp $_pth_sshpubkey $_cnt_nm:/tmp/
    docker exec $_cnt_nm bash -c "cat /tmp/$_fn_sshpubkey > $_pth_authkeysfile"
    docker exec $_cnt_nm rm /tmp/$_fn_sshpubkey
    docker exec $_cnt_nm chmod 600 $_pth_authkeysfile
    docker exec $_cnt_nm chown $_cnt_user:$_cnt_user $_pth_authkeysfile
}

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
  # TODO: Check output ssh command and only in case of error reprovision ssh public key
  prov_sshpubkey $CNT_NM vagrant ./script/data/builder-keys/ssh.pub /home/vagrant/.ssh/authorized_keys
  ssh -oStrictHostKeyChecking=no vagrant@127.0.0.1 -p 22222 -i ./script/data/builder-keys/ssh.priv
  ;;

*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


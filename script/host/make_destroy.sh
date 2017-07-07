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
  # No-op
  ;;

#-----------------------------------------------------------------------------
# When using Vagrant.
vagrant)
  vagrant destroy
  ;;

#-----------------------------------------------------------------------------
# When using LXD.
lxd)
  source ./script/host/lxd_destroy.sh
  ;;

#-----------------------------------------------------------------------------
# When using Docker.
docker)
  
  # Function to ask the user for confirmation.
  function diag_confirm_yn {
    local _preRsp=$1
    local _msg="$2"
    
    if [ "$_preRsp" = "" ];then
    echo -n $_msg ;read rsp
    else
    rsp=$_preRsp
    fi
        
    while :
        do
            case $rsp in
            [y,Y]*)
                break
                ;;
    
            [n,N]*)
                exit
                ;;
    
            *)
                echo "Unrecognized response: ${rsp}."
                echo -n $_msg ;read rsp
                ;;
            esac
        done
  }
 
  # Ask the user for confirmation.
  diag_confirm_yn "" "Do you want to remove base builder image? Note: rebuilding it may take a long time (y/n/yes/no): "

  # Stop and remove the container.
  docker stop $CNT_NM
  docker rm $CNT_NM

  # Remove the builder base image.
  docker rmi $CNT_TP

  ;;

#-----------------------------------------------------------------------------
*)
  echo "Error! Unknown sandbox provider ${SANDBOX_PROVIDER}"
  exit 1
  ;;

esac


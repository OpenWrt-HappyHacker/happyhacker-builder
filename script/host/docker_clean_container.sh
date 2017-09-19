#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e


# Load the common container functions
source script/host/container_common_functions.sh

# Load the build configuration variables. Rewrite default values if it was setted.
source script/config.sh

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##


ECHO_TLT " Clean docker enviroment."
ECHO_MSG " Removing container $CNT_NM ."

sudo docker stop $CNT_NM
sudo docker rm $CNT_NM

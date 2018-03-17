#!/bin/bash

# This script parses the YAML configuration file into Bash variables.
# It is not meant to be run as a command, but included into other scripts.

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
set -e

# YAML parser in Bash, source: https://stackoverflow.com/a/21189044/426293
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Get the configuration file names.
CONFIG_DIR="$(dirname ${BASH_SOURCE})/../config"
CONFIG_DIR="$(realpath ${CONFIG_DIR})"
GLOBAL_CONFIG="${CONFIG_DIR}/global.yml"
USER_CONFIG="${CONFIG_DIR}/user.yml"

# Load the global configuration file. This file should always be there.
if [ -f "${GLOBAL_CONFIG}" ]
then
    eval $(parse_yaml "${GLOBAL_CONFIG}")
else
    echo "ERROR: missing configuration file: ${GLOBAL_CONFIG}"
    exit 1
fi

# Load the user configuration overrides, if present.
# Ignore if the file does not exist.
if [ -f "${USER_CONFIG}" ]
then
    eval $(parse_yaml "${USER_CONFIG}")
fi

# For debugging only... this prints out all variables.
#set


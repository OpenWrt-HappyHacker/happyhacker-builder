#!/bin/bash

# Vagrant-specific provisioning script.
# Does some tweaking of the vagrant home folder.

# Fail on error for any line.
set -e

# Enable colors in the console.
if [ -e "~/.bashrc" ]; then
    sed -i s/\\#force_color_prompt\\=yes/force_color_prompt=yes/ ~/.bashrc
fi

# Copy our custom Wget configuration file.
cp /OUTSIDE/script/data/wgetrc ~/.wgetrc


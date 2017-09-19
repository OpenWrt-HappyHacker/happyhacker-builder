#!/bin/bash

# Set the error mode so the script fails automatically if any command in it fails.
# This saves us a lot of error checking code down below.
#set -e


# Container default conf
#CNT_TP='alpine:3.5'
CNT_TP='nimmis/alpine-micro' # TODO: Create custom Dockerfile
CNT_NM='BuilderNG' # Pass name as script argument
CNT_TG='HHv1' # container version tag

CNT_USR='maker'
CNT_USR_HOME="/home/$CNT_USR"
CNT_SHAREPATH='/OUTSIDE'

HST_BASEDIR="$(pwd)"
#HST_SHAREPATH="$HST_BASEDIR/INSIDE"
HST_SHAREPATH="$HST_BASEDIR"



# Load the common container functions
source script/host/container_common_functions.sh

# Load the build configuration variables. Rewrite default values if it was setted.
source script/config.sh

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

ECHO_TLT " Checks "

ECHO_MSG " Docker services ..."
sudo systemctl start docker

ECHO_TLT " Configurations "

ECHO_MSG " Launching container ..."

mkdir -p $HST_SHAREPATH

_hostname="${CNT_NM}.dck.lol"
# TODO: Check behaviour of Z option in -v parameter in other non selinux distro
sudo docker run  -e "container=docker" \
            -e "TERM=xterm-256color" \
            -e 'PS1=[\u@\h \w] \$ ' \
            --hostname $_hostname \
            --name $CNT_NM \
            -v $HST_SHAREPATH:/$CNT_SHAREPATH:rw,Z \
            -d \
            $CNT_TP 


ECHO_MSG " Preparing container"

#TODO: Add sshd support

RRUN 'apk update'
RRUN 'apk add nano bash'
RRUN "adduser $CNT_USR -D" # Add user without password
RRUN "ln -s /home/$CNT_USR /INSIDE"

RRUN "echo search $_hostname > /etc/resolv.conf"
RRUN "echo nameserver 208.67.222.222 >> /etc/resolv.conf"
RRUN "echo nameserver  208.67.220.222 >> /etc/resolv.conf"


RRUN 'apk add asciidoc git bash bc binutils bzip2 fastjar flex g++ gawk gcc gettext intltool'
RRUN 'apk add libusb-dev  make mercurial  patch python-dev rsync ruby subversion util-linux'
RRUN 'apk add build-base libressl-dev zlib-dev  patch bison make autoconf gettext unzip'
RRUN 'apk add ncurses5-libs ncurses-libs ncurses-dev ncurses-terminfo gawk xz-libs wget'
RRUN 'apk add tar findutils grep file openssl libattr gettext linux-headers'

RRUN 'apk add e2fsprogs-dev libc-dev libstdc++'
#RRUN 'apk add openjdk7'
    
    # gettext
    
#  bcc (missing):
#    required by: world[bcc]
#  bin86 (missing):
#    required by: world[bin86]
#  gcc-multilib (missing):
#    required by: world[gcc-multilib]
#  genisoimage (missing):
#    required by: world[genisoimage]
#  jikespg (missing):
#    required by: world[jikespg]
#  libboost-dev (missing):
#    required by: world[libboost-dev]
#  libgtk2.0-dev (missing):
#    required by: world[libgtk2.0-dev]
#  libncurses5-dev (missing):
#    required by: world[libncurses5-dev]
#  libxml-parser-perl (missing):
#    required by: world[libxml-parser-perl]
#  sdcc (missing):
#    required by: world[sdcc]
#  sharutils (missing):
#    required by: world[sharutils]
#  xsltproc (missing):
#    required by: world[xsltproc]

#### FIXED ####
#  git-core (missing): # fix with git
#    required by: world[git-core]
#  openjdk-7-jdk (missing): # fix with openjdk7
#    required by: world[openjdk-7-jdk]

#  build-essential (missing): # fix with build-base
#    required by: world[build-essential]

#  libssl-dev (missing): # fix with libressl-dev
#    required by: world[libssl-dev]

#  perl-modules (missing): # fix default perl install include similar package
#    required by: world[perl-modules]

#  zlib1g-dev (missing): # fix with zlib-dev
#    required by: world[zlib1g-dev]

RRUN  'apk add coreutils makepasswd'

  #colorgcc (missing):
  #  required by: world[colorgcc]
  #colormake-0.9.20140503-r0:
  #  masked in: @testing
  #  satisfies: world[colormake]

# PROVISION ENVIROMENT
RRUN '/OUTSIDE/script/guest/prov-environment.sh'

# Shell as root
#RRUN  'bash' '/OUTSIDE'

# shell as $CNT_USR
#RUN  'bash' '/OUTSIDE'

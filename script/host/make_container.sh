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

# Load the build configuration variables. Rewrite default values if it was setted.
source script/config.sh

# Auxiliar functions.
# TODO???: Move to auxiliar lib

RUN ()
{

_cmd=$1
_path=$2
_user=$3

if [ -z "$_path" ]; then # Set default path if it is empty
    _path='/tmp'
fi

if [ -n "$_user" ]; then # If not empty
    RRUN $_cmd $_path $_user
else
    RRUN $_cmd $_path "$CNT_USR"
fi

}

RRUN ()
{
_cmd=$1
_path=$2
_user=$3

if [ -z "$_path" ]; then # Set default path if it is empty
    _path='/tmp'
fi

if [ -z "$_user" ]; then # If empty root
    echo "CMD ROOT $_path"
    #ssh root@X.X.X.X bash -c "cd $_path;$(echo $_cmd)"
    sudo docker exec -it $CNT_NM sh -c "cd $_path;$(echo $_cmd)"
    
else 
    echo "CMD USER"
    #ssh root@X.X.X.X su $_user -c bash -c "cd $_path;$(echo $_cmd); "
    sudo docker exec -it $CNT_NM su $_user -c sh -c "cd $_path;$(echo $_cmd); "
fi

}

#function SHELL {
#    local _cnt_nm=$1
#    RUN $_cnt_nm 'source /etc/profile;sh'
#}


function ECHO_TLT {
    local _msg=$1

    echo
    echo "---------------------------------------------------------------------"
    echo "$_msg"
    echo "---------------------------------------------------------------------"
    echo

}

function ECHO_MSG {
    local _msg=$1

    echo
    echo "$_msg"
    echo

}


#function INSTALL_VAGRANT {
#    ECHO_MSG " Installing form source vagrant ..."
#    # Installs form source vagrant
#    RUN  'apk add git ruby ruby-bundler ruby-dev ruby-json ruby-rake libffi libffi-dev zlib zlib-dev libxml2 libxml2-dev libxslt libxslt-dev build-base'
#
#    RUN  'wget https://codeload.github.com/mitchellh/vagrant/zip/v1.9.1 -O vagrant.zip' '/usr/local/share'
#    RUN  'unzip vagrant.zip' '/usr/local/share'
#    RUN  'bundle config build.nokogiri --use-system-libraries' '/usr/local/share/vagrant-1.9.1'
#    RUN  'bundle install' '/usr/local/share/vagrant-1.9.1'
#    RUN  'bundle --binstubs exec' '/usr/local/share/vagrant-1.9.1'
#    RUN  'ln -sf /usr/local/share/vagrant-1.9.1/exec/vagrant /usr/bin/vagrant'
#    #RUN  'mkdir -p ~/.vagrant.d'
#    #RUN  'cp vagrant* ~/.vagrant.d/' '/usr/local/share/vagrant-1.9.1/keys'
#}

ECHO_TLT " Configurations "

ECHO_MSG " Launching container ..."

mkdir -p $HST_SHAREPATH


# TODO: Check behaviour of Z option in -v parameter in other non selinux distro
sudo docker run  -e "container=docker" \
            -e "TERM=xterm-256color" \
            -e 'PS1=[\u@\h \w] \$ ' \
            --hostname ${CNT_NM}.dck.lol \
            --name $CNT_NM \
            -v $HST_SHAREPATH:/$CNT_SHAREPATH:rw,Z \
            -d \
            $CNT_TP 



ECHO_MSG " Preparing container"
RRUN  'apk update'
RRUN  'apk add nano bash'
RRUN  "adduser $CNT_USR -D" # Add user without password
RRUN  "ln -s /home/$CNT_USR /INSIDE"


RRUN  'apk add asciidoc git bash bc binutils bzip2 fastjar flex g++ gawk gcc gettext intltool libusb-dev  make mercurial  patch python-dev rsync ruby subversion unzip util-linux wget build-base libressl-dev zlib-dev openjdk7'

#  bcc (missing):
#    required by: world[bcc]
#  bin86 (missing):
#    required by: world[bin86]
#  gcc-multilib (missing):
#    required by: world[gcc-multilib]
#  genisoimage (missing):
#    required by: world[genisoimage]
#  git-core (missing): # fix with git
#    required by: world[git-core]
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


# Shell as root
RRUN  'bash' '/OUTSIDE'

# shell as $CNT_USR
#RUN  'bash' '/OUTSIDE'

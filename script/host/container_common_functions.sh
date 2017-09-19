#!/bin/bash

RUN ()
{

_cmd=$1
_path=$2
_user=$3

if [ -z "$_path" ]; then # Set default path if it is empty
    _path='/tmp'
fi

if [ -n "$_user" ]; then # If not empty
    echo "RUN _user"
    RRUN $_cmd $_path $_user
else
    echo "RUN CNT_USR"
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
    _user=$CNT_USR
    echo "CMD USER CNT_USR:$CNT_USR user: $_user path:$_path cmd:$_cmd"
    #ssh root@X.X.X.X su $_user -c bash -c "cd $_path;$(echo $_cmd); "
    sudo docker exec -it $CNT_NM su $_user -c sh -c "cd $_path;$(echo $_cmd); "
fi

}

CONTBUILD ()
{
  # Create the base image if it doesn't exist.
  if [[ "$(docker images -q $CNT_TP 2> /dev/null)" == "" ]]
  then
    docker build -t $CNT_TP .
  fi
    
}


# Provision ssh public keys to a local docker container
prov_sshpubkey () {
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

    sudo docker cp $_pth_sshpubkey $_cnt_nm:/tmp/
    sudo docker exec $_cnt_nm bash -c "cat /tmp/$_fn_sshpubkey > $_pth_authkeysfile"
    sudo docker exec $_cnt_nm rm /tmp/$_fn_sshpubkey
    sudo docker exec $_cnt_nm chmod 600 $_pth_authkeysfile
    sudo docker exec $_cnt_nm chown $_cnt_user:$_cnt_user $_pth_authkeysfile
}



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

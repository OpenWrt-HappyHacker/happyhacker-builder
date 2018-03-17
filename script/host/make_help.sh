#!/bin/bash
echo "
To build all profiles just type:
    make all

To list the available profiles:
    make list

To build a specific profile:
    make bin/<profile>

To clean the output files (but not the container/VM):
    make clean

To completely clean up everything
(including the container/VM and output files):
    make dirclean

To modify the OpenWrt configuration for an existing profile:
    make menuconfig CONFIG=<profile>

To quickly SSH into the build container/VM:
    make ssh

To control the build container/VM:
    make up
    make suspend
    make destroy
"


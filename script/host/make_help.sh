#!/bin/bash
echo "
To build all profiles just type:
    make all

To list the available profiles:
    make list

To build a specific profile:
    make bin/<profile>

To clean the build files (but not the VM or output files):
    make clean

To completely clean up everything
(including the container/VM and output files):
    make dirclean

To begin preparing a new profile from scratch:
    make menuconfig

To modify the OpenWrt configuration for an existing profile:
    make menuconfig CONFIG=<profile>

To quickly SSH into the build contianer/VM:
    make ssh

To control the build container:
    make up
    make suspend
    make destroy
"


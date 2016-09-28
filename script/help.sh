#!/bin/bash
echo "
To build all targets just type:
    make all

To list the available targets:
    make list

To build a specific target:
    make bin/<target>

To clean the build files (but not the VM or output files):
    make clean

To completely clean up everything (including the VM and output files):
    make dirclean

To begin preparing a new firmware image from scratch:
    make menuconfig

To modify the configuration for an existing target firmware image:
    make menuconfig CONFIG=<target>

Vagrant VM control:
    make up
    make suspend
    make destroy
"

This directory contains a subdirectory for each target firmware image. Inside each one you will find the .bin files with the firmware image itself, a makefile and some useful scripts. Try cd'ing into them and running "make help" to see what you can do.

Here you will also find some tarfiles. They contain the OpenWrt source code files and many precompiled binaries. If you delete them, the build system will regenerate them for you - but this may take a long while! Do not touch them unless you know what you're doing.

For more details on how it all works, see: script/guest/build.sh

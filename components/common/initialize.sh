#!/bin/bash
set -e

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Change the boot order of some of the services.
/OUTSIDE/script/guest/set_service_order.sh busybox sysntpd 97
/OUTSIDE/script/guest/set_service_order.sh base-files "done" 99

# If on debug mode...
if [ $DEBUG_MODE -ne 0 ]
then

    # Tag the build as a debug one.
    touch "${OUTPUT_DIR}/__DEBUG__"
    touch ./files/__DEBUG__

    # Do not replace the fstab mount service.
    # This assumes "debug mode" means ext-storage or ext-root.
    rm -f ./files/etc/init.d/fstab
fi

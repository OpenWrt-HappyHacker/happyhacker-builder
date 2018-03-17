This directory contains data files used by the build system. Some of them are described below:

wifisdb.csv:
  This is the CSV file with the Wi-Fi configuration for the devices. Here you define the names and passwords of the Wi-Fi networks the device will try to connect to when it boots. Pay attention to this file! If you don't configure it correctly, you'll find yourself unable to connect to your device, as it will have no network.

ca.key and ca.crt:
  These are the root certificates created after the first build. You will want to add this root certificate to your browser to prevent SSL warnings when you connect to your device.

Makefile.build and flash.sh:
  These are automatically copied to the output folder after building. They provide some helpful commands for automating the flashing process. Do not edit them unless you really know what you're doing!

The rest of these files are used internally for various reasons and you probably don't need to touch them at all.

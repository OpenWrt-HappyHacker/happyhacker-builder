#!/bin/bash
set -e

# Create some directories needed for Jirafeau to work.
mkdir -p ./files/tmp_php_uploads@usb
mkdir -p ./files/tmp_php_session@usb
mkdir -p ./files/www/storage-jirafeau@usb/files
mkdir -p ./files/www/storage-jirafeau@usb/links
mkdir -p ./files/www/storage-jirafeau@usb/async
mkdir -p ./files/www/storage-jirafeau@usb/alias
mkdir -p ./files/www/nstorage-jirafeau@usb/static
mkdir -p ./files/www/lib/locales
chmod 777 ./files/tmp_php_*
chmod 766 -R ./files/www/storage-jirafeau@usb/
chmod 755 -R ./files/www/WEBtor/

# Create a Tor hidden service for the web server.
/OUTSIDE/script/guest/create_hidden_service.sh WEBtor 443

# Get the Tor hidden service hostname.
ONION_HOSTNAME=$(cat ./files/etc/tor/lib/hidden_service/WEBtor/hostname)

# Create a new TLS certificate for the web server.
/OUTSIDE/script/guest/create_ssl_cert.sh ${ONION_HOSTNAME} ./files/etc/ uhttpd

# Change the Jirafeau configuration file to use the new webroot.
sed -i s/https:\\/\\/\([^\\.]+\\.onion\)[\\:\\/]/${ONION_HOSTNAME}/g ./files/www/WEBtor/lib/config.local.php

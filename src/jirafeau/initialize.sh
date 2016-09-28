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

# Create a new Tor certificate for the hidden service.
mkdir -p ./files/etc/tor/lib/hidden_service/WEBtor/
/vagrant/script/create_tor_key.sh ./files/etc/tor/lib/hidden_service/WEBtor/
ONION_HOSTNAME=$(cat ./files/etc/tor/lib/hidden_service/WEBtor/hostname)

# Add the new hidden service to the torrc configuration file.
/vagrant/script/add_hidden_service.sh /etc/tor/lib/hidden_service/WEBtor/ 443 127.0.0.1:443

# Create a new TLS certificate for the web server.
# Depends on the Tor service keys being already created.
/vagrant/script/create_ssl_cert.sh ${ONION_HOSTNAME} ./files/etc/ uhttpd

# Change the Jirafeau configuration file to use the new webroot.
sed -i s/https:\\/\\/\([^\\.]+\\.onion\)[\\:\\/]/${ONION_HOSTNAME}/g ./files/www/WEBtor/lib/config.local.php

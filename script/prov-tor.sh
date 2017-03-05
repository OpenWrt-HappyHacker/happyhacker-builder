#!/bin/bash

# Fail on error for any line.
set -e
sudo apt-get update
sudo apt-get install -y tor
sudo service tor stop
sudo sed -i s/RUN_DAEMON\\=\\\"yes\\\"/RUN_DAEMON=\"no\"/g /etc/default/tor
sudo cp /vagrant/script/torrc_global /etc/tor/torrc
sudo mkdir -p /home/vagrant/.hiddenservice
sudo cp /vagrant/script/torrc_local /home/vagrant/.hiddenservice/torrc
sudo chown -R vagrant:vagrant /home/vagrant/.hiddenservice


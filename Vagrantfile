# -*- mode: ruby -*-
# vi: set ft=ruby :
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
load File.join(File.dirname(__FILE__), "script", "config.sh")
Vagrant.configure(2) do |config|
  config.vm.define "openwrt-happyhacker-build-vm"
  config.vm.box = "ubuntu/trusty64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = VM_MEMORY
    vb.cpus = NUM_CORES
  end
  config.vm.provision :shell, :inline => "/vagrant/script/provision.sh"
  config.vm.box_check_update = false
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
load File.join(File.dirname(__FILE__), "script", "config.sh")
ENV['VAGRANT_DEFAULT_PROVIDER'] = VIRT_PROVIDER
ENV['LC_ALL']="en_US.UTF-8"
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


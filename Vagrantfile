# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Detect if we're running on Windows. Refuse to run if so.
if Gem.win_platform?
  abort("Windows is not supported.")
end

# Load the configuration files.
# This method for loading them is crap, but will mostly work for what we need.
GLOBAL = YAML.load_file(File.join(File.dirname(__FILE__), "config", "global.yml"))
if File.file?(File.join(File.dirname(__FILE__), "config", "user.yml"))
  USER = YAML.load_file(File.join(File.dirname(__FILE__), "config", "user.yml"))
else
  USER = {}
end

# Get the variables we need from the configuration.
begin
  VIRT_PROVIDER = USER['VIRT']['PROVIDER']
rescue
  VIRT_PROVIDER = GLOBAL['VIRT']['PROVIDER']
end
begin
  VM_MEMORY = USER['VM_MEMORY']
rescue
  VM_MEMORY = GLOBAL['VM_MEMORY']
end
begin
  NUM_CORES = USER['NUM_CORES']
rescue
  NUM_CORES = GLOBAL['NUM_CORES']
end

# Some Linux distros require these environment variables to be set.
ENV['VAGRANT_DEFAULT_PROVIDER'] = VIRT_PROVIDER
ENV['LC_ALL']="en_US.UTF-8"

# Vagrant configuration.
Vagrant.configure(2) do |config|

  # Name of the VM.
  config.vm.define "openwrt-happyhacker-build-vm"

  # Box to use. We chose Ubuntu Trusty for simplicity.
  # Ubuntu Xenial did not work at all for us. :P
  config.vm.box = "ubuntu/trusty64"

  # Let's turn off box updates checking, they are annoying.
  # This is entirely optional of course. :)
  config.vm.box_check_update = false

  # VirtualBox specific settings.
  # NOTE: this is the only provider we currently support.
  # But if you get it working for other providers, let us know!
  config.vm.provider "virtualbox" do |vb|

    # Set the amount of memory and CPU cores of the VM.
    vb.memory = VM_MEMORY
    vb.cpus = NUM_CORES

  end

  # Provisioning script.
  config.vm.provision :shell, :inline => "/vagrant/script/guest/prov-vagrant.sh"

end


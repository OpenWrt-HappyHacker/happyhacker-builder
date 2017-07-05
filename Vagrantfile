# -*- mode: ruby -*-
# vi: set ft=ruby :

# Detect if we're running on Windows. Refuse to run if so.
if Gem.win_platform?
  abort("Windows is not supported.")
end

# Load the configuration variables directly.
# This is why we need to keep the config file simple,
# so that it works both in Bash and Ruby.
load File.join(File.dirname(__FILE__), "script", "config.sh")

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


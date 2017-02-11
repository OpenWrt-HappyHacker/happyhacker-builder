# -*- mode: ruby -*-
# vi: set ft=ruby :
load File.join(File.dirname(__FILE__), "script", "config.sh")
ENV['VAGRANT_DEFAULT_PROVIDER'] = VIRT_PROVIDER

if VIRT_PROVIDER == "docker"

  Vagrant.configure(2) do |config|
    config.vm.provider(:docker) do |d|
      #d.image = "nishidayuya/docker-vagrant-ubuntu:14.04"
      #d.image = "happyhacker/openwrtbuilder:0.1"
      #d.build_image "happyhacker/openwrtbuilder:0.1"
      d.vagrant_machine = "hh-openwrtbuilder"
      d.build_dir="."
      #d.create_args = ['--privileged=true', '-v /sys/fs/cgroup:/sys/fs/cgroup:ro']
      d.create_args = ['--privileged']
      d.remains_running = true
      d.build_args = ["--tag=hh-openwrtbuilder"]
      d.name = "hh-openwrtbuilder"
      d.has_ssh = true
    end
    config.vm.provision :shell, :inline => "/vagrant/script/provision.sh"
    config.vm.box_check_update = false
  end

elsif VIRT_PROVIDER == "virtualbox"

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

else
  puts "Error: unknown provider: " + VIRT_PROVIDER
end

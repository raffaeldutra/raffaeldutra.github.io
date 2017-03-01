# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "private_network", ip: "192.168.33.130"

  config.vm.provision "shell", inline: <<-SHELL
    sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable
    sudo apt-get update
    sudo apt-get autoremove -y
    sudo apt-get install -y golang git nginx snapd python-pip
    sudo snap install hugo
  SHELL

    config.vm.synced_folder ".", "/var/www/html",
    id: "v-root",
    mount_options: ["rw", "tcp", "nolock", "noacl", "async"],
    type: "nfs",
    nfs_udp: false
end

# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure(2) do |config|

  module OS
    def OS.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def OS.mac?
      (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def OS.unix?
      !OS.windows?
    end

    def OS.linux?
      OS.unix? and not OS.mac?
    end
  end

  mount   = __dir__
  mountDirectory = "/var/www/html"

  config.vm.box = "ubuntu/trusty64"
  config.vm.network "forwarded_port", guest: 80, host: 8000
  config.vm.network "private_network", ip: "192.168.33.130"

  config.vm.provision "shell", inline: <<-SHELL
    sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable
    sudo apt-get update
    sudo apt-get autoremove -y
    sudo apt-get install -y golang git nginx snapd python-pip
    sudo snap install hugo
  SHELL

    if OS.linux?
      config.vm.synced_folder "#{mount}", "#{mountDirectory}", id: "v-root", mount_options: ["rw", "tcp", "nolock", "noacl", "async"], type: "nfs", nfs_udp: false
    else
      config.vm.synced_folder "#{mount}", "#{mountDirectory}", type: "nfs"
    end
end

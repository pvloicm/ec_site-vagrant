# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION ||= "2"
confDir = $confDir ||= File.expand_path(File.dirname(__FILE__))
provisionPath =  confDir + "/provision.sh"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # If running on MacOS or Ubuntu
  config.vm.box = "centos/8"
  config.vm.box_url = "http://cloud.centos.org/centos/8/x86_64/images/CentOS-8-Vagrant-8.1.1911-20200113.3.x86_64.vagrant-virtualbox.box"
  # If running on Windows
  # config.vm.box = "centos/8"

  config.vm.box_check_update = false

  # Open port for PGSQL client access such as Navicat
  config.vm.network "forwarded_port", guest: 5432, host: 65432

  config.vm.network "private_network", ip: "192.168.33.10"

  # Change project directory
  # config.vm.synced_folder "{project_name}", "/var/www/giftland"
  config.vm.synced_folder "./sol_traveler_ec-site", "/var/www/sol_traveler_ec" , :mount_options => ["dmode=777,fmode=666"]

  if File.exist? provisionPath then
    config.vm.provision "shell", path: provisionPath, privileged: false, keep_color: true
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Required modules
require 'yaml'

Vagrant.require_version ">= 1.8.7"
# Validate if all the required plugins are present
# vagrant-hostmanager replaced
required_plugins = ["vagrant-cachier", "vagrant-vbguest", "vagrant-hosts"]
required_plugins.each do |plugin|
  if not Vagrant.has_plugin?(plugin)
    raise "Required vagrant plugin #{plugin} not found. Please run `vagrant plugin install #{plugin}`"
  end
end

# Configuration files
CONFIGURATION_FILE = 'configuration/vars/stack-config.yml'
HOSTS_FILE = 'configuration/hosts/all'
HOST_VARS_PATH = 'configuration/host_vars'

# Read configuration file(s)
instances_config = YAML.load_file(File.join(File.dirname(__FILE__), CONFIGURATION_FILE))
hosts_config = File.open(HOSTS_FILE, 'w+')


# configure instance names and private ip addresses

instances_arr = Array.new
private_ipam_arr = Array.new

for i in 1..Integer(instances_config['stack_size'])
  instance_name = "bdb-node-#{i}"
  instance_ip_address = "10.20.30.#{i+10}"
  instances_arr.push instance_name
  private_ipam_arr.push instance_ip_address
  hosts_config.puts("#{instance_ip_address} ansible_user=vagrant ansible_password=vagrant")
  File.open("#{HOST_VARS_PATH}/#{instance_ip_address}", "w+") {|f| \
  f.write("ansible_ssh_private_key_file: .vagrant/machines/#{instance_name}/virtualbox/private_key") }
end

hosts_config.close

Vagrant.configure("2") do |config|
  instances_arr.each_with_index do |instance, index|
    config.vm.define "#{instance}" do |node|
      node.vm.box = instances_config['stack_box_name']
      node.vm.box_check_update = false
      # Workaround until vagrant cachier plugin supports dnf
      if !(instances_config['stack_box_name'].include? "fedora")
        if Vagrant.has_plugin?("vagrant-cachier")
          node.cache.scope = :box
        end
      elsif instances_config['stack_box_name'] == "bento/ubuntu-18.04"
        if Vagrant.has_plugin?("vagrant-vbguest")
          node.vbguest.auto_update = true
          node.vbguest.auto_reboot = true
          config.vbguest.no_install = true
          config.vbguest.no_remote = true
        end
      end
      node.vm.synced_folder  "bigchaindb", "/opt/stack/bigchaindb" 
      node.vm.hostname = instance
      node.vm.provision :hosts, :sync_hosts => true
      node.ssh.insert_key = true
      node.vm.network :private_network, ip: private_ipam_arr[index]
      node.vm.provider :virtualbox do |vb, override|
        vb.customize ["modifyvm", :id, "--memory", instances_config['stack_vm_memory'].to_s]
        vb.customize ["modifyvm", :id, "--cpus", instances_config['stack_vm_cpus'].to_s]
      end
    end
  end
end
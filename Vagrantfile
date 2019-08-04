# -*- mode: ruby -*-
# vi: set ft=ruby :

$conf = {
  "master" => {
    "num_instances" => 1, # should probably be only one.
    "instance_name_prefix" => "m",
    "vm_memory" => 1024,
    "vm_cpus" => 2,
    "vb_cpuexecutioncap" => 60,
    "ip_address_prefix" => "10.100.1.",
    "ip_address_start" => 101,
    "shared_folders" => {
      # host => guest
      "." => "/vagrant"
    }
  },
  "worker" => {
    "num_instances" => 2,
    "instance_name_prefix" => "w",
    "vm_memory" => 2048,
    "vm_cpus" => 2,
    "vb_cpuexecutioncap" => 60,
    "ip_address_prefix" => "10.100.1.",
    "ip_address_start" => 111,
    "shared_folders" => {
      # host => guest
      "." => "/vagrant"
    }
  }
}

Vagrant.require_version ">= 1.9.0"

def configure_machine(config, conf, i, hostname, etc_hosts)
  config.vm.boot_timeout = 600
  config.vm.box = "ubuntu/bionic64"
  config.vm.hostname = hostname

  # Forward ssh keys
  config.ssh.forward_agent = true

  # Disable SSH password for 16.04 - we'll add the insecure Vagrant key
  # (don't worry, it's just an example and gets replaced anyway)
  config.ssh.password = nil

  # Machine specs
  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.memory = conf["vm_memory"]
    vb.cpus = conf["vm_cpus"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", conf["vb_cpuexecutioncap"]]
  end

  # ip address
  ip_num = conf["ip_address_start"] + i - 1
  ip = conf["ip_address_prefix"] + "#{ip_num}"
  config.vm.network :private_network, ip: ip

  # Disable shared folders
  config.vm.synced_folder ".", "/vagrant", disabled: false

  # Export console
  config.vm.provider "virtualbox" do |vb|
     vb.customize [ "modifyvm", :id, "--uart1", "0x3F8", "4" ]
     vb.customize [ "modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, "console.#{hostname}.log") ]
  end

  # Add the machines to /etc/hosts
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    set -euxo pipefail
    echo "#{etc_hosts}" >> /etc/hosts
    apt-get update
    apt-get dist-upgrade -y -qq
    apt-get autoremove -y
  SHELL
end

def provision_master(config, conf, etc_hosts)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name, etc_hosts)
      config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        set -euxo pipefail
      SHELL
    end
  end
end

def provision_worker(config, conf, etc_hosts)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name, etc_hosts)
      config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        set -euxo pipefail
      SHELL
    end
  end
end

def etc_hosts_data(conf)
  hosts = []
  conf.each do |t, conf|
    (1..conf["num_instances"]).each do |i|
      ip_num = conf["ip_address_start"] + i - 1
      ip = conf["ip_address_prefix"] + "#{ip_num}"
      hostname_prefix = conf["instance_name_prefix"]
      hostname = "%s%02d" % [hostname_prefix, i]
      hosts.push("#{ip} #{hostname}")
    end
  end
  return hosts.join("\n")
end

Vagrant.configure(2) do |config|
  #config.hostmanager.enabled = true
  #config.hostmanager.manage_host = false
  #config.hostmanager.manage_guest = true
  #config.vm.provision :hostmanager
  etc_hosts = etc_hosts_data($conf)

  provision_master(config, $conf["master"], etc_hosts)
  provision_worker(config, $conf["worker"], etc_hosts)
end

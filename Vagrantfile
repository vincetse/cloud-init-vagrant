# -*- mode: ruby -*-
# vi: set ft=ruby :

$conf = {
  "master" => {
    "num_instances" => 1, # should probably be only one.
    "instance_name_prefix" => "c",
    "vm_memory" => 1024,
    "vm_cpus" => 2,
    "vb_cpuexecutioncap" => 100,
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
    "vm_memory" => 1024,
    "vm_cpus" => 2,
    "vb_cpuexecutioncap" => 100,
    "ip_address_prefix" => "10.100.1.",
    "ip_address_start" => 111,
    "shared_folders" => {
      # host => guest
      "." => "/vagrant"
    }
  }
}

Vagrant.require_version ">= 1.9.0"

def configure_machine(config, conf, i, hostname)
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

  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    set -euxo pipefail
    apt-get update
    apt-get upgrade -y -qq
  SHELL

  # Citus Data
  # https://docs.citusdata.com/en/v8.1/installation/multi_machine_debian.html
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    set -euxo pipefail

    curl -fsSL https://install.citusdata.com/community/deb.sh | bash
    apt-get -y install postgresql-11-citus-8.1
    pg_conftool 11 main set shared_preload_libraries citus
    pg_conftool 11 main set listen_addresses '*'

    echo "host    all             all             10.0.0.0/8              trust" >> /etc/postgresql/11/main/pg_hba.conf
    service postgresql restart
    update-rc.d postgresql enable
    sudo -i -u postgres -- psql -c "CREATE EXTENSION citus;"
  SHELL
end

def provision_master(config, conf, worker_ips)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name)

      # Citus Data
      # https://docs.citusdata.com/en/v8.1/installation/multi_machine_debian.html
      worker_ips.each do |ip|
        config.vm.provision "shell", inline: <<-SHELL
          export DEBIAN_FRONTEND=noninteractive
          set -euxo pipefail
          sudo -i -u postgres -- psql -c "SELECT * from master_add_node('#{ip}', 5432);"
        SHELL
      end

      config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        set -euxo pipefail
        sudo -i -u postgres -- psql -c "SELECT * FROM master_get_active_worker_nodes();"
      SHELL
    end
  end
end

def provision_worker(config, conf)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name)
      config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        set -euxo pipefail
      SHELL
    end
  end
end

def get_worker_ips(conf)
  ips = []
  (1..conf["num_instances"]).each do |i|
    # ip address
    ip_num = conf["ip_address_start"] + i - 1
    ip = conf["ip_address_prefix"] + "#{ip_num}"
    ips.push(ip)
  end
  return ips
end

Vagrant.configure(2) do |config|
  #config.hostmanager.enabled = true
  #config.hostmanager.manage_host = false
  #config.hostmanager.manage_guest = true
  #config.vm.provision :hostmanager
  worker_ips = get_worker_ips($conf["worker"])
  provision_worker(config, $conf["worker"])
  provision_master(config, $conf["master"], worker_ips)
end

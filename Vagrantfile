# -*- mode: ruby -*-
# vi: set ft=ruby :

$conf = {
  "master" => {
    "num_instances" => 1, # should probably be only one.
    "instance_name_prefix" => "m",
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
    "num_instances" => 1,
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

$nic = "enp0s8"
$cni_version = "0.7.4"
$containerd_version = "1.2.3"
$stellar_version = "0.2.0"

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
    apt-get install -y -qq \
      make \
      runc
  SHELL

  # CNI plugin
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    set -euxo pipefail
    mkdir -p /opt/cni/bin

    curl -fsSL https://github.com/containernetworking/plugins/releases/download/v#{$cni_version}/cni-plugins-amd64-v#{$cni_version}.tgz \
      -o cni.tgz
    mkdir tmp
    cd tmp
    tar zxf ../cni.tgz
    for i in *; do
      install $i /opt/cni/bin
    done
    cd -
    rm -rf tmp cni.tgz

  SHELL

  # Containerd
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    set -euxo pipefail

    curl -fsSL https://github.com/containerd/containerd/releases/download/v#{$containerd_version}/containerd-#{$containerd_version}.linux-amd64.tar.gz \
      -o containerd.tgz
    tar zxf containerd.tgz
    cd bin
    for i in *; do
      install $i /usr/local/bin
    done
    cd -
    rm -rf bin containerd.tgz
    mkdir /etc/containerd/
    containerd config default > /etc/containerd/config.toml
    cp /vagrant/containerd.service /etc/systemd/system
    systemctl enable containerd.service
    systemctl start containerd.service
  SHELL

  # Stellar
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    set -euxo pipefail

    cp /vagrant/stellar.tar.bz2 .
    tar jxf stellar.tar.bz2
    cd bin
    install sctl /usr/local/bin
    install stellar /usr/local/bin
    install stellar-cni-ipam /opt/cni/bin
    cd -
    rm -rf bin stellar.tar.bz2

    #mkdir tmp
    #cd tmp
    #curl -fsSL https://github.com/ehazlett/stellar/releases/download/v#{$stellar_version}/stellar-#{$stellar_version}-linux-amd64.tar.gz -o stellar.tgz
    #tar zxf stellar.tgz
    #install sctl /usr/local/bin
    #install stellar /usr/local/bin
    #install stellar-cni-ipam /opt/cni/bin
    #cd -
    #rm -rf tmp
  SHELL
end

def provision_master(config, conf)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name)

      config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        set -euxo pipefail

        stellar config --nic #{$nic} \
          > /usr/local/etc/stellar.conf
        cp /vagrant/stellar.service /etc/systemd/system
        systemctl enable stellar.service
        systemctl start stellar.service
      SHELL
    end
  end
end

def provision_worker(config, conf, master_ip)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name)
      config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        set -euxo pipefail

        stellar config --nic #{$nic} --peer #{master_ip}:7946 \
          > /usr/local/etc/stellar.conf
        cp /vagrant/stellar.service /etc/systemd/system
        systemctl enable stellar.service
        systemctl start stellar.service
      SHELL
    end
  end
end

def get_master_ip(conf)
  ip = nil
  (1..conf["num_instances"]).each do |i|
    # ip address
    ip_num = conf["ip_address_start"] + i - 1
    ip = conf["ip_address_prefix"] + "#{ip_num}"
    break
  end
  return ip
end

Vagrant.configure(2) do |config|
  #config.hostmanager.enabled = true
  #config.hostmanager.manage_host = false
  #config.hostmanager.manage_guest = true
  #config.vm.provision :hostmanager
  master_ip = get_master_ip($conf["master"])
  provision_master(config, $conf["master"])
  provision_worker(config, $conf["worker"], master_ip)
end

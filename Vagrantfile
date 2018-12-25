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
    "vm_memory" => 2048,
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
$kubeadm_token = "a36ef3.6f6960dfc28f769d"
$pod_network_cidr = "192.168.0.0/16"

Vagrant.require_version ">= 1.9.0"

def configure_machine(config, conf, i, hostname)
  config.vm.boot_timeout = 600
  config.vm.box = "ubuntu/xenial64"
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
end

def provision_master(config, conf)
  (1..conf["num_instances"]).each do |i|
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    config.vm.define vm_name = hostname do |config|
      configure_machine(config, conf, i, vm_name)
      config.vm.provision "shell", inline: <<-SHELL
        set -eux
        # Add apt repos to install Docker and Kubernetes
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" \
          > /etc/apt/sources.list.d/docker.list
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" \
          > /etc/apt/sources.list.d/kubernetes.list

        # update the system
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get dist-upgrade -y

        # install Docker and Kubernetes
        apt-get install -y \
          docker-ce=18.06.0~ce~3-0~ubuntu \
          kubelet \
          kubeadm \
          kubectl \
          sysstat

        # initialize kubeadm
        kubeadm init \
          --token=#{$kubeadm_token} \
          --token-ttl=0 \
          --pod-network-cidr=#{$pod_network_cidr} \
          --apiserver-advertise-address=10.100.1.101
        export KUBECONFIG=/etc/kubernetes/admin.conf

        # Calico
        kubectl apply \
          -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

        # Make sure ubuntu user can run kubectl
        sudo -u ubuntu -- mkdir -p ~ubuntu/.kube
        cp -i /etc/kubernetes/admin.conf ~ubuntu/.kube/config
        chown -R ubuntu:ubuntu ~ubuntu/.kube
        cp ~ubuntu/.kube/config /vagrant/kubeconfig

        # Helm
        curl -fsSL https://storage.googleapis.com/kubernetes-helm/helm-v2.7.1-linux-amd64.tar.gz -o helm.tar.gz
        tar -zxvf helm.tar.gz
        mv linux-amd64/helm /usr/local/bin
        helm init
        kubectl create serviceaccount tiller --namespace kube-system
        kubectl create -f /vagrant/tiller-clusterrolebinding.yaml
        helm init --service-account tiller --upgrade
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
        set -eux
        # Add apt repos to install Docker and Kubernetes
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" \
          > /etc/apt/sources.list.d/docker.list
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" \
          > /etc/apt/sources.list.d/kubernetes.list
        add-apt-repository ppa:gluster/glusterfs-5

        # update the system
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get dist-upgrade -y

        # install Docker and Kubernetes
        apt-get install -y \
          docker-ce=18.06.0~ce~3-0~ubuntu \
          glusterfs-client \
          kubelet \
          kubeadm \
          kubectl \
          sysstat

        # initialize kubeadm
        kubeadm join \
          --token=#{$kubeadm_token} \
          --discovery-token-unsafe-skip-ca-verification \
          10.100.1.101:6443
      SHELL
    end
  end
end

Vagrant.configure(2) do |config|
  #config.hostmanager.enabled = true
  #config.hostmanager.manage_host = false
  #config.hostmanager.manage_guest = true
  #config.vm.provision :hostmanager

  provision_master(config, $conf["master"])
  provision_worker(config, $conf["worker"])
end

# -*- mode: ruby -*-
# vi: set ft=ruby :


$conf = {
  "gluster" => {
    "num_instances" => 3,
    "instance_name_prefix" => "g",
    "vm_memory" => 1024,
    "vm_cpus" => 1,
    "vb_cpuexecutioncap" => 100,
    "ip_address_prefix" => "10.100.0.",
    "ip_address_start" => 51,
    "shared_folders" => {
      # host => guest
      "." => "/vagrant"
    }
  }
}

Vagrant.require_version ">= 1.9.0"

def create_machine_class(config, conf, role)
  conf = conf[role]

  (1..conf["num_instances"]).each do |i|
    config.vm.boot_timeout = 600
    config.vm.box = "ubuntu/zesty64"
    hostname_prefix = conf["instance_name_prefix"]
    hostname = "%s%02d" % [hostname_prefix, i]
    # Generate the ISO image used for first boot
    if ARGV[0] == "up"
      `make iso role=#{role} hostname=#{hostname} iso=nocloud-#{role}-#{hostname}.iso`
    end
    config.vm.define vm_name = hostname do |config|
      #config.vm.hostname = vm_name

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
      config.vm.synced_folder ".", "/vagrant", disabled: true

      # Tweak virtualbox
      config.vm.provider :virtualbox do |vb|
          # Attach nocloud.iso to the virtual machine
          vb.customize [
              "storageattach", :id,
              "--storagectl", "SCSI",
              "--port", "1",
              "--type", "dvddrive",
              "--medium", "nocloud-#{role}-#{hostname}.iso"
          ]
      end

      config.vm.provider "virtualbox" do |vb|
        vb.customize [ "modifyvm", :id, "--uart1", "0x3F8", "4" ]
        vb.customize [ "modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, "console.#{hostname}.log") ]
      end
    end
  end
end

Vagrant.configure(2) do |config|
  create_machine_class(config, $conf, "gluster")
end

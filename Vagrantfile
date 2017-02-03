# -*- mode: ruby -*-
# vi: set ft=ruby :


CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "nocloud.iso")
$ip_address = "192.168.97.2"


Vagrant.require_version ">= 1.9.0"

if ARGV[0] == "up"
  `make`
   puts "ip address #{$ip_address}"
end

Vagrant.configure(2) do |config|
    config.vm.box = "ubuntu/xenial64"

    # Forward ssh keys
    config.ssh.forward_agent = true

    # Disable SSH password for 16.04 - we'll add the insecure Vagrant key
    # (don't worry, it's just an example and gets replaced anyway)
    config.ssh.password = nil

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    config.vm.network "private_network", ip: $ip_address

    # To use your main public/private key pair, uncomment these lines:
    # config.ssh.private_key_path = File.expand_path("~/.ssh/id_rsa")
    # config.ssh.insert_key = false

    # Disable shared folders
    config.vm.synced_folder ".", "/vagrant", disabled: true

    config.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        vb.gui = false

        # Customize the amount of memory on the VM:
        vb.memory = "1024"
    end 

    # Tweak virtualbox
    config.vm.provider :virtualbox do |vb|
        # Attach nocloud.iso to the virtual machine
        vb.customize [
            "storageattach", :id,
            "--storagectl", "SCSI",
            "--port", "1",
            "--type", "dvddrive",
            "--medium", CLOUD_CONFIG_PATH
        ]
    end
end

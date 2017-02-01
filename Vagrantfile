# -*- mode: ruby -*-
# vi: set ft=ruby :


CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "nocloud.iso")
$ndrives = 3
$drive_size_gb = 5
$controller_name = "SCSI"


Vagrant.require_version ">= 1.9.0"

if ARGV[0] == "up"
  `make`
end

Vagrant.configure("2") do |config|

    # Disable automatic box update checking. If you disable this, then
    # boxes will only be checked for updates when the user runs
    # `vagrant box outdated`. This is not recommended.
    config.vm.box_check_update = true

    config.vm.box = "ubuntu/xenial64"

    # Forward ssh keys
    config.ssh.forward_agent = true

    # Disable SSH password for 16.04 - we'll add the insecure Vagrant key
    # (don't worry, it's just an example and gets replaced anyway)
    config.ssh.password = nil

    # To use your main public/private key pair, uncomment these lines:
    # config.ssh.private_key_path = File.expand_path("~/.ssh/id_rsa")
    # config.ssh.insert_key = false

    # Disable shared folders
    #config.vm.synced_folder ".", "/vagrant", disabled: true

    config.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        vb.gui = false

        # Customize the amount of memory on the VM:
        vb.memory = "512"
    end 

    # Tweak virtualbox
    config.vm.provider "virtualbox" do |vb|
        # Attach nocloud.iso to the virtual machine
        vb.customize [
            "storageattach", :id,
            "--storagectl", $controller_name,
            "--port", "1",
            "--type", "dvddrive",
            "--medium", CLOUD_CONFIG_PATH
        ]
    end

    # Additional Storage
    config.vm.provider "virtualbox" do |vb|
        base_port = 1
        # Add a few drives
        (1..$ndrives).each do |drive|
          file_to_disk = "raid-disk%02d.vdi" % [drive]
          unless File.exist?(file_to_disk)
            vb.customize ['createmedium', 'disk', '--format', 'VDI', '--filename', file_to_disk, '--size', ($drive_size_gb * 1024)]
          end
          port = base_port + drive
          vb.customize ['storageattach', :id, '--storagectl', $controller_name, '--port', port, '--type', 'hdd', '--medium', file_to_disk]
        end
    end
end

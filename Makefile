addr = 10.100.1.101:9000
nodes:
	sctl --addr $(addr) cluster nodes
	sctl --addr $(addr) cluster info

create:
	sctl --addr $(addr) apps create -f ./example.conf

list:
	sctl --addr $(addr) apps list

ns:
	sctl --addr $(addr) nameserver list

addr = 10.100.1.101:9000
nodes:
	sctl --addr $(addr) cluster nodes
	sctl --addr $(addr) cluster info

create:
	sctl --addr $(addr) apps create -f ./hello-world.conf

delete inspect:
	sctl --addr $(addr) apps $@ hello-world

list:
	sctl --addr $(addr) apps list

ns:
	sctl --addr $(addr) nameserver list

curl:
	curl -H "Host: example.com" localhost

demo: create inspect ns curl delete

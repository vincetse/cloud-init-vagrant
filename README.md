# Consul Cluster in Vagrant

A 5-node [Consul][a01] cluster with compute resources to run services on to demonstrate how Consul works.

## Prerequisites

Install mkisofs/genisoimage.

```
# On Debian/Ubuntu:
sudo apt-get install genisoimage

# On OS X Macports:
sudo port install cdrtools
```

## Usage

### Cluster Creation

```
# Create the first Consul server to bootstrap the Consul cluster
vagrant up bootstrap

# Create the rest of the Consul cluster
vagrant up /consul-.+/

# OPTIONAL: Destroy the bootstrap Consul server (since it's outlived it usefulness in this setup)
vagrant destroy -f bootstrap

# Create compute VM
vagrant up compute-01
```

### Registering Services

```
# Run a Docker container
docker run \
  --detach \
  --publish 80 \
  --env SERVICE_80_NAME=hello-world \
  --env SERVICE_80_CHECK_SCRIPT='curl --silent --fail http://0.0.0.0:$SERVICE_PORT/health' \
  --env SERVICE_80_CHECK_INTERVAL=5s \
  --env SERVICE_80_CHECK_TIMEOUT=3s \
  --env SERVICE_TAGS=http \
  infrastructureascode/hello-world

# Look up its Consul DNS name with the SRV record
dig @0.0.0.0 -p 8600 -t SRV hello-world.service.dc1.consul
```

## References

1. [Consul website][a01]
1. [Wicked Awesome Tech: Setting up Consul Service Discovery for Mesos in 10 Minutes][a02]
1. [Get Docker for Ubuntu][a03]
1. [kelseyhightower/setup-network-environment][a04]
1. [AWS Compute Blog: Service Discovery via Consul with Amazon ECS][a05]
1. [gliderlabs/registrator][a06]
1. [Sreenivas Makam's Blog: Service Discovery with Consul][a07]


[a01]: https://www.consul.io/
[a02]: http://www.wickedawesometech.us/2016/04/setting-up-consul-service-discovery-in.html
[a03]: https://docs.docker.com/engine/installation/linux/ubuntu/
[a04]: https://github.com/kelseyhightower/setup-network-environment
[a05]: https://aws.amazon.com/blogs/compute/service-discovery-via-consul-with-amazon-ecs/
[a06]: https://github.com/gliderlabs/registrator
[a07]: https://sreeninet.wordpress.com/2016/04/17/service-discovery-with-consul/

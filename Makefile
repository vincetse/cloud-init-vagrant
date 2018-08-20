OS := $(shell uname -s)
ifeq ($(OS), Darwin)
  ISO_CMD=mkisofs
else
  ISO_CMD=genisoimage
endif

all: nocloud.consul-bootstrap.iso nocloud.consul-server.iso nocloud.compute.iso

nocloud.%.iso:  user-data.%.txt
	cp -vf $< user-data
	$(ISO_CMD) \
		-joliet -rock \
		-volid "cidata" \
		-output $@ meta-data user-data
	rm user-data

clean:
	rm -f nocloud.*.iso user-data

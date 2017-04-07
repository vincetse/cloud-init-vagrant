OS := $(shell uname -s)
ifeq ($(OS), Darwin)
  ISO_CMD=mkisofs
else
  ISO_CMD=genisoimage
endif

all: nocloud.leader.iso nocloud.follower.iso

nocloud.%.iso:  user-data.%
	cp --verbose --force $< user-data
	$(ISO_CMD) \
		-joliet -rock \
		-volid "cidata" \
		-output $@ meta-data user-data
	rm user-data

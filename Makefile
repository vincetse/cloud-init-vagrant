OS := $(shell uname -s)
ifeq ($(OS), Darwin)
  ISO_CMD=mkisofs
else
  ISO_CMD=genisoimage
endif

all: nocloud-master.iso nocloud-worker.iso

nocloud-master.iso: meta-data user-data-master
	cp -f user-data-master user-data
	$(ISO_CMD) \
		-joliet -rock \
		-volid "cidata" \
		-output nocloud-master.iso meta-data user-data
	rm -f user-data

nocloud-worker.iso: meta-data user-data-worker
	cp -f user-data-worker user-data
	$(ISO_CMD) \
		-joliet -rock \
		-volid "cidata" \
		-output nocloud-worker.iso meta-data user-data
	rm -f user-data

clean:
	rm -f nocloud-master.iso nocloud-worker.iso

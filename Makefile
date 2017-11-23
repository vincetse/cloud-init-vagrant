OS := $(shell uname -s)
ifeq ($(OS), Darwin)
  ISO_CMD=mkisofs
else
  ISO_CMD=genisoimage
endif

meta-data:
	echo "instance-id: iid-"`openssl rand -hex 8` > $@
	echo "local-hostname: $(hostname)" >> $@

iso: meta-data
	cp -f user-data-$(role) user-data
	$(ISO_CMD) \
		-joliet -rock \
		-volid "cidata" \
		-output $(iso) meta-data user-data
	rm -f meta-data user-data

clean:
	rm -f meta-data *.iso *.log

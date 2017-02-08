ifeq ($(OS), Darwin)
  ISO_CMD=mkisofs
else
  ISO_CMD=genisoimage
endif

nocloud.iso: meta-data user-data
	$(ISO_CMD) \
		-joliet -rock \
		-volid "cidata" \
		-output nocloud.iso meta-data user-data

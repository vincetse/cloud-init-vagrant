OS := $(shell uname -s)
ifeq ($(OS), Darwin)
  ISO_CMD=mkisofs
else
  ISO_CMD=genisoimage
endif

ssl_tgz = ssl.tgz
ssl_dir = ssl
ca_key_pem = $(ssl_dir)/ca-key.pem
ca_pem = $(ssl_dir)/ca.pem

all: nocloud-master.iso nocloud-worker.iso $(ssl_tgz)

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

$(ssl_dir):
	mkdir -p $@

$(ssl_tgz): $(ssl_dir)
	# https://github.com/coreos/coreos-kubernetes/blob/master/lib/init-ssl-ca
	openssl genrsa -out "$(ca_key_pem)" 2048
	openssl req -x509 -new -nodes -key "$(ca_key_pem)" -days 10000 -out "$@" -subj "/CN=kube-ca"
	tar zcf $@ $(ssl_dir)

clean:
	rm -f nocloud-master.iso nocloud-worker.iso $(ca_key_pem) $(ca_key) $(ssl_tgz)
	rm -rf $(ssl_dir)

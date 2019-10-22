NAME            ?= pydeps
VERSION         ?= 5.5.7-el7-1
PRODNAME        := $(NAME)-$(VERSION)
DESTDIR         := dest
OUTPUT          := $(DESTDIR)/$(PRODNAME).tar.gz
TMPDIR          := /tmp
WHEELDIR        := wheelhouse
BUILDDIR        := $(TMPDIR)/$(NAME)-$(VERSION)
REQUIREMENTS_3RD := requirements_3rd.txt
REQUIREMENTS_ZEN := requirements_zen.txt
REQUIREMENTS_OPT := requirements_opt.txt
PKGMAKEFILE     := Makefile.pkg
CENTOS_BASE_TAG := 1.1.7-java
BUILD_IMAGE     := zenoss/build-wheel


build: Dockerfile
	docker build -t $(BUILD_IMAGE) .
	docker run --rm           \
		-v $${PWD}:/mnt/build \
		-w /mnt/build         \
		-e NAME=$(NAME)       \
		-e VERSION=$(VERSION) \
		zenoss/build-wheel    \
		make $(OUTPUT)

Dockerfile: Dockerfile.in
	@sed \
		-e "s/%UID%/$$(id -u)/g" \
		-e "s/%GID%/$$(id -g)/g" \
		-e "s/%CENTOS_BASE_TAG%/$(CENTOS_BASE_TAG)/g" \
		< Dockerfile.in > Dockerfile

$(DESTDIR):
	@mkdir -p $@

$(BUILDDIR):
	@mkdir -p $@

$(OUTPUT): $(BUILDDIR)/$(WHEELDIR) $(DESTDIR)
	OLD=$$PWD; cd $(TMPDIR); tar czf $${OLD}/$(@) $(PRODNAME)


# The atomic package requires special attention. The CFFI package needs
# to installed so that a proper binary wheel can be built for atomic.
CFFI_REQ := $(shell sed -n '/cffi/p' $(REQUIREMENTS_3RD))

$(BUILDDIR)/$(WHEELDIR): $(BUILDDIR)
	@sudo pip install $(CFFI_REQ)
	@pip wheel --wheel-dir=$@ \
		-r $(REQUIREMENTS_3RD) wheel
	@cp $(REQUIREMENTS_3RD) $(BUILDDIR)

	# Add zenoss local packages
	@pip wheel --wheel-dir=$@ \
		--extra-index-url http://zenpip.zenoss.eng/simple/ \
		--trusted-host zenpip.zenoss.eng \
		-r $(REQUIREMENTS_ZEN) wheel
	@cp $(REQUIREMENTS_ZEN) $(BUILDDIR)

	# Add Optional package requirements
	@pip wheel --wheel-dir=$@ \
		--extra-index-url http://zenpip.zenoss.eng/simple/ \
		--trusted-host zenpip.zenoss.eng \
		-r $(REQUIREMENTS_OPT) wheel
	@cp $(REQUIREMENTS_OPT) $(BUILDDIR)
	@cp Makefile.pkg $(BUILDDIR)/Makefile
	@cp -r patches $(BUILDDIR)/patches

clean:
	rm -f Dockerfile
	rm -rf $(DESTDIR)
	rm -rf $(BUILDDIR)

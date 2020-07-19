include versions.mk

NAME          = pydeps
RELEASE       = 1
PLATFORM      = el7
PRODUCT       = $(NAME)-$(VERSION)-$(PLATFORM)-$(RELEASE)
DESTDIR       = dest
OUTPUT        = $(DESTDIR)/$(PRODUCT).tar.gz
TMPDIR        = /tmp
WHEELDIR      = wheelhouse
BUILDDIR      = $(TMPDIR)/$(NAME)-$(VERSION)
REQUIREMENTS  = $(BUILDDIR)/requirements.txt
REQ_3RD       = requirements_3rd.txt
REQ_ZEN       = requirements_zen.txt
REQ_OPT       = requirements_opt.txt
PKGMAKEFILE   = Makefile.pkg
BUILD_IMAGE   = zenoss/build-wheel
BASEIMAGE_TAG = $(CENTOS_BASE_VERSION)-java


build: Dockerfile
	docker build -t $(BUILD_IMAGE) .
	docker run --rm           \
		-v $${PWD}:/mnt/build \
		-w /mnt/build         \
		-e NAME=$(NAME)       \
		-e VERSION=$(VERSION) \
		$(BUILD_IMAGE)        \
		make $(OUTPUT)

Dockerfile: Dockerfile.in
	@sed \
		-e "s/%UID%/$$(id -u)/g" \
		-e "s/%GID%/$$(id -g)/g" \
		-e "s/%TAG%/$(BASEIMAGE_TAG)/g" \
		< $< > $@

$(DESTDIR):
	@mkdir -p $@

$(BUILDDIR):
	@mkdir -p $@

$(OUTPUT): $(BUILDDIR)/$(WHEELDIR) $(DESTDIR) $(REQUIREMENTS)
	OLD=$$PWD; cd $(TMPDIR); tar czf $${OLD}/$(@) $(PRODUCT)

$(REQUIREMENTS): | $(BUILDDIR)
$(REQUIREMENTS): $(REQ_3RD) $(REQ_ZEN) $(REQ_OPT)
	@cat $^ > $@
	@sed -e "/^[\s]*$$/d" -e "/^#/d" -i $@

# The atomic package requires special attention. The CFFI package needs
# to installed so that a proper binary wheel can be built for atomic.
CFFI_REQ := $(shell sed -n '/cffi/p' $(REQ_3RD))

$(BUILDDIR)/$(WHEELDIR): $(BUILDDIR)
	@sudo pip install $(CFFI_REQ)
	@pip wheel --wheel-dir=$@ -r $(REQ_3RD) wheel

	# Add zenoss local packages
	@pip wheel --wheel-dir=$@ \
		--extra-index-url http://zenpip.zenoss.eng/simple/ \
		--trusted-host zenpip.zenoss.eng \
		-r $(REQ_ZEN) wheel

	# Add Optional package requirements
	@pip wheel --wheel-dir=$@ \
		-r $(REQ_OPT) wheel
	@cp Makefile.pkg $(BUILDDIR)/Makefile
	@cp -r patches $(BUILDDIR)/patches


clean:
	rm -f Dockerfile
	rm -rf $(DESTDIR)
	rm -rf $(BUILDDIR)

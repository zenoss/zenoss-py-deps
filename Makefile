NAME            ?= pydeps
VERSION         ?= 6.0.0-el7-1
PRODNAME        := $(NAME)-$(VERSION)
DESTDIR         := dest
OUTPUT          := $(DESTDIR)/$(PRODNAME).tar.gz
TMPDIR          := /tmp
CACHE           := cache
WHEELDIR        := wheelhouse
BUILDDIR        := $(TMPDIR)/$(NAME)-$(VERSION)
REQUIREMENTS    := $(BUILDDIR)/requirements.txt
MAKEFILE        := $(BUILDDIR)/Makefile
REQ_3RD         := requirements_3rd.txt
REQ_ZEN         := requirements_zen.txt
REQ_OPT         := requirements_opt.txt
CENTOS_BASE_TAG := 1.1.7-java
BUILD_IMAGE     := zenoss/build-wheel

ifneq ($(wildcard ./patches),)
PATCHES := add_patches
else
PATCHES := 
endif


build: $(IMAGEDIR)/Dockerfile $(CACHE)
	docker build -t $(BUILD_IMAGE) $(IMAGEDIR)
	docker run --rm           \
		-v $${PWD}:/mnt/build \
		-w /mnt/build         \
		-e NAME=$(NAME)       \
		-e VERSION=$(VERSION) \
		zenoss/build-wheel    \
		make $(OUTPUT)

$(IMAGEDIR)/Dockerfile: | $(IMAGEDIR)
$(IMAGEDIR)/Dockerfile: Dockerfile.in
	@sed \
		-e "s/%UID%/$$(id -u)/g" \
		-e "s/%GID%/$$(id -g)/g" \
		-e "s/%CENTOS_BASE_TAG%/$(CENTOS_BASE_TAG)/g" \
		< $< > $@

$(DESTDIR) $(BUILDDIR) $(BUILDDIR)/patches:
	@mkdir -p $@

$(OUTPUT): | $(DESTDIR)
$(OUTPUT): $(BUILDDIR)/$(WHEELDIR) $(MAKEFILE) $(REQUIREMENTS) $(PATCHES)
	OLD=$$PWD; cd $(TMPDIR); tar czf $${OLD}/$(@) $(PRODNAME)

$(REQUIREMENTS): | $(BUILDDIR)
$(REQUIREMENTS): $(REQ_3RD) $(REQ_ZEN) $(REQ_OPT)
	@cat $^ > $@
	@sed -e "/^[\s]*$$/d" -e "/^#/d" -i $@

# The atomic package requires special attention. The CFFI package needs
# to installed so that a proper binary wheel can be built for atomic.
CFFI_REQ := $(shell sed -n '/cffi/p' $(REQ_3RD))

$(BUILDDIR)/$(WHEELDIR): $(BUILDDIR) $(REQ_3RD) $(REQ_ZEN) $(REQ_OPT)
	@sudo pip install $(CFFI_REQ)
	@pip wheel --wheel-dir=$@ -r $(REQ_3RD) wheel
	@pip wheel --wheel-dir=$@ \
		--extra-index-url http://zenpip.zenoss.eng/simple/ \
		--trusted-host zenpip.zenoss.eng \
		-r $(REQ_ZEN) wheel
	@pip wheel --wheel-dir=$@ -r $(REQ_OPT) wheel

$(MAKEFILE): | $(BUILDDIR)
$(MAKEFILE): Makefile.pkg
	@cp Makefile.pkg $(BUILDDIR)/Makefile

add_patches: $(BUILDDIR)/patches
	@cp -r patches $(BUILDDIR)/patches

clean:
	rm -f Dockerfile
	rm -rf $(DESTDIR) $(BUILDDIR) $(CACHE) $(IMAGEDIR)

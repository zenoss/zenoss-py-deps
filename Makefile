NAME            ?= pydeps
VERSION         ?= $(shell cat VERSION)-el7-1
PRODNAME        := $(NAME)-$(VERSION)
DESTDIR         := dest
ARTIFACT        := $(DESTDIR)/$(PRODNAME).tar.gz
TMPDIR          := /tmp
CACHE           := cache
WHEELDIR        := wheelhouse
BUILDDIR        := $(TMPDIR)/$(NAME)-$(VERSION)
REQUIREMENTS    := $(BUILDDIR)/requirements.txt
REQ_3RD         := requirements_3rd.txt
REQ_ZEN         := requirements_zen.txt
REQ_OPT         := requirements_opt.txt
CENTOS_BASE_TAG := 1.1.9-java
BUILD_IMAGE     := zenoss/build-wheel

unittest2_pkg = unittest2-1.1.0-py2.py3-none-any.whl

IMAGEDIR = image

.PHONY: build build-image

build: build-image $(CACHE)
	docker run --rm           \
		-v $${PWD}:/mnt/build \
		-w /mnt/build         \
		-e NAME=$(NAME)       \
		-e VERSION=$(VERSION) \
		$(BUILD_IMAGE)        \
		make $(ARTIFACT)

build-image: $(IMAGEDIR)/Dockerfile
	docker build -t $(BUILD_IMAGE) $(IMAGEDIR)

artifact: $(ARTIFACT)

$(IMAGEDIR)/Dockerfile: | $(IMAGEDIR)
$(IMAGEDIR)/Dockerfile: Dockerfile.in
	@sed \
		-e "s/%UID%/$$(id -u)/g" \
		-e "s/%GID%/$$(id -g)/g" \
		-e "s/%CENTOS_BASE_TAG%/$(CENTOS_BASE_TAG)/g" \
		-e "s/%PACKAGES%/$(shell cat image-packages.txt | tr '\n' ' ')/g" \
		< $< > $@

$(DESTDIR) $(CACHE) $(BUILDDIR) $(IMAGEDIR):
	@mkdir -p $@

$(ARTIFACT): $(BUILDDIR)/$(WHEELDIR) $(BUILDDIR)/$(WHEELDIR)/$(unittest2_pkg) $(BUILDDIR)/install.sh $(BUILDDIR)/patches $(DESTDIR) $(REQUIREMENTS)
	OLD=$$PWD; cd $(TMPDIR); tar czf $${OLD}/$(@) $(PRODNAME)

$(REQUIREMENTS): | $(BUILDDIR)
$(REQUIREMENTS): $(REQ_3RD) $(REQ_ZEN) $(REQ_OPT)
	@cat $^ > $@
	@sed -e "/^[\s]*$$/d" -e "/^#/d" -i $@
	@echo "unittest2==1.1.0" >> $@

# The atomic package requires special attention. The CFFI package needs
# to installed so that a proper binary wheel can be built for atomic.
CFFI_REQ := $(shell sed -n '/cffi/p' $(REQ_3RD))

$(BUILDDIR)/$(WHEELDIR): $(BUILDDIR)
	@pip install \
		--user \
		--no-color --no-python-version-warning \
		--cache-dir /mnt/build/$(CACHE) \
		$(CFFI_REQ)
	# Add required 3rd party packages
	@pip wheel \
		--no-color --no-python-version-warning \
		--no-deps \
		--cache-dir /mnt/build/$(CACHE) \
		--wheel-dir=$@ \
		-r $(REQ_3RD) wheel
	# Add zenoss local packages
	@pip wheel \
		--no-color --no-python-version-warning \
		--no-deps \
		--cache-dir /mnt/build/$(CACHE) \
		--wheel-dir=$@ \
		--extra-index-url http://zenpip.zenoss.eng/simple/ \
		--trusted-host zenpip.zenoss.eng \
		-r $(REQ_ZEN) wheel
	# Add Optional package requirements
	@pip wheel \
		--no-color --no-python-version-warning \
		--no-deps \
		--cache-dir /mnt/build/$(CACHE) \
		--wheel-dir=$@ \
		-r $(REQ_OPT) wheel

$(BUILDDIR)/install.sh: install.sh
	@cp $^ $@

$(BUILDDIR)/patches: patches
	@cp -r $^ $@


# unittest2==1.1.0 incorrectly declares argparse as a dependency for Python >2.6.
# This has been fixed, but unreleased, in unittest2's source code.
# So, these targets pull down the source code and build an updated unittest2==1.1.0 that correctly
# skips the argparse dependency on Python versions >= 2.7.

unittest2:
	@hg clone https://hg.python.org/unittest2

$(BUILDDIR)/$(WHEELDIR)/$(unittest2_pkg): unittest2
	@pip install --no-color --no-python-version-warning --user traceback2
	@cd unittest2; hg update -r 541; sed -i -e "s/version=VERSION/version=str(VERSION)/" setup.py; python setup.py bdist_wheel
	@cp unittest2/dist/$(unittest2_pkg) $@

clean:
	rm -f Dockerfile
	rm -rf $(DESTDIR) $(BUILDDIR) $(CACHE) $(IMAGEDIR) unittest2

NAME         ?= pydeps
VERSION      ?= 5.5.1-el7-1
PRODNAME     := $(NAME)-$(VERSION)
DESTDIR      := dest
OUTPUT       := $(DESTDIR)/$(PRODNAME).tar.gz
TMPDIR       := /tmp
WHEELDIR     := wheelhouse
BUILDDIR     := $(TMPDIR)/$(NAME)-$(VERSION)
REQUIREMENTS := requirements.txt
PKGMAKEFILE  := Makefile.pkg

build: Dockerfile
	docker build -t zenoss/build-wheel .
	docker run --rm           \
		-v $${PWD}:/mnt/build \
		-w /mnt/build         \
		-e NAME=$(NAME)       \
		-e VERSION=$(VERSION) \
		zenoss/build-wheel    \
		make $(OUTPUT)

Dockerfile:
	@sed -e "s/%UID%/$$(id -u)/g" -e "s/%GID%/$$(id -g)/g" < Dockerfile.in > Dockerfile

$(DESTDIR):
	@mkdir -p $@

$(BUILDDIR):
	@mkdir -p $@

$(OUTPUT): $(BUILDDIR)/$(WHEELDIR) $(DESTDIR)
	OLD=$$PWD; cd $(TMPDIR); tar czf $${OLD}/$(@) $(PRODNAME)


# The atomic package requires special attention. The CFFI package needs
# to installed so that a proper binary wheel can be built for atomic.
CFFI_REQ := $(shell sed -n '/cffi/p' $(REQUIREMENTS))

$(BUILDDIR)/$(WHEELDIR): $(BUILDDIR)
	@sudo pip install $(CFFI_REQ)
	@pip wheel --wheel-dir=$@ \
		--extra-index-url http://zenpip.zenoss.eng/simple/ \
		--trusted-host zenpip.zenoss.eng \
		-r $(REQUIREMENTS) wheel
	@cp $(REQUIREMENTS) $(BUILDDIR)
	@cp Makefile.pkg $(BUILDDIR)/Makefile
	@cp -r patches $(BUILDDIR)/patches

clean:
	rm -f Dockerfile
	rm -rf $(DESTDIR)
	rm -rf $(BUILDDIR)

NAME         ?= pydeps
VERSION      ?= 5.2.0-el7-2
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

$(BUILDDIR)/$(WHEELDIR): $(BUILDDIR)
	@pip wheel --wheel-dir=$@ \
		--extra-index-url http://zenpip.zendev.org/simple/ \
		--trusted-host zenpip.zendev.org \
		-r $(REQUIREMENTS) wheel
	@cp $(REQUIREMENTS) $(BUILDDIR)
	@cp Makefile.pkg $(BUILDDIR)/Makefile
	@cp -r patches $(BUILDDIR)/patches

clean:
	rm -f Dockerfile
	rm -rf $(DESTDIR)
	rm -rf $(BUILDDIR)

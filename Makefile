VERSION      ?= 5.0.0
OUTPUT       := pydeps-$(VERSION).tar.gz
BUILDDIR     := /tmp/pydeps-build
REQUIREMENTS := requirements.txt

build:
	docker build -t zenoss/build-wheel .
	docker run -rm -v $${PWD}:/mnt/build -w /mnt/build zenoss/build-wheel /bin/bash -c \
		"make VERSION=$(VERSION) BUILDDIR=$(BUILDDIR) REQUIREMENTS=$(REQUIREMENTS) $(OUTPUT) && \
		 chown -R $$(id -u):$$(id -g) $(OUTPUT)"

$(OUTPUT): $(BUILDDIR)
	tar czf $(@) $(<D)

$(BUILDDIR):
	@pip wheel --wheel-dir=$@ -r $(REQUIREMENTS)

clean:
	rm -f pydeps.*.tar.gz
	rm -rf $(BUILDDIR)

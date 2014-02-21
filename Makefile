OUTPUT       := pydeps.tgz
BUILDDIR     := /tmp/pydeps-build
REQUIREMENTS := requirements.txt

default: $(OUTPUT)

build:
	docker build -t zenoss/build-wheel .
	docker run -v .:/mnt/build -w /mnt/build zenoss/build-wheel /bin/bash -c \
		"make BUILDDIR=$(BUILDDIR) REQUIREMENTS=$(REQUIREMENTS) && \
		 chown -R $${UID}:$${UID} $(OUTPUT)"

$(OUTPUT): $(BUILDDIR)
	tar czf $(@) $(<D)

$(BUILDDIR):
	@pip wheel --wheel-dir=$@ -r $(REQUIREMENTS)

clean:
	rm -f $(OUTPUT)
	rm -rf $(BUILDDIR)

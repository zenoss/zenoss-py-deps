OUTPUT       := pydeps.tgz
BUILDDIR     := /tmp/pydeps-build
REQUIREMENTS := $(wildcard *.requirements.txt)


default: $(OUTPUT)

build:
	docker build -t zenoss/build-wheel .
	docker run -rm -v $${PWD}:/mnt/build -w /mnt/build zenoss/build-wheel /bin/bash -c \
		"make BUILDDIR=$(BUILDDIR) REQUIREMENTS=$(REQUIREMENTS) && \
		 chown -R $$(id -u):$$(id -g) $(OUTPUT)"

$(OUTPUT): $(BUILDDIR)
	tar czf $(@) $(<D)

$(BUILDDIR):
	@pip wheel --wheel-dir=$@ -r $(REQUIREMENTS)

clean:
	rm -f $(OUTPUT)
	rm -rf $(BUILDDIR)

requirements.txt:
	@docker build -t zenoss/build-wheel .
	@docker run -rm -v $${PWD}:/mnt/build -w /mnt/build zenoss/build-wheel /bin/bash -c \
		"make .docker.requirements.txt; chown $$(id -u):$$(id -g) $(@) 2>/dev/null"

.docker.requirements.txt:
	@virtualenv /tmp/pydeps-venv
	@/tmp/pydeps-venv/bin/pip install --no-install -r requirements.in
	@SEPARATOR="=="; \
	 for f in /tmp/pydeps-venv/build/*; do \
		VERSIONFILE=$$(find $$f -name PKG-INFO | head -n 1); \
		if [ -n "$${VERSIONFILE}" ]; then \
			NAMEVERSION="$$(cat $${VERSIONFILE} | head -n 3 | tail -n 2 | awk {'print $$2'})"; \
			echo $${NAMEVERSION} | python -c "import sys; print '=='.join(sys.stdin.read().strip().split())" >> requirements.txt; \
		fi; \
	 done
	@rm -rf /tmp/pydeps-venv

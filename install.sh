#!/bin/bash

SITE_PACKAGES=$(python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")

pip --no-color --no-python-version-warning install --no-deps --no-index --no-cache-dir --find-links=./wheelhouse -r ./requirements.txt wheel
cat patches/* | patch -d ${SITE_PACKAGES} -p0

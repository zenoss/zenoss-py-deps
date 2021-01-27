#!/bin/bash

pip --no-color --no-python-version-warning install --no-index --no-cache-dir --find-links=./wheelhouse -r ./requirements.txt wheel
cat patches/* | patch -d $(python -c "import pip, os.path; print os.path.dirname(pip.__path__[0])") -p0

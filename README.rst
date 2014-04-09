Python Dependency Builder
=========================

This will build an archive containing all dependencies specified in requirements.txt, along with any of their dependencies, in wheel_ format. It also generates and includes a Makefile that will install all the dependencies using whatever Python/pip you choose.

Usage
-----
Just run ``make``.

Installation
------------
The artifact that comes out may be installed thusly:

.. code-block:: bash

    tar xzf pydeps-5.0.0.tar.gz
    cd pydeps-5.0.0
    PYTHON=/path/to/python PIP=/path/to/pip make
    
If ``PYTHON`` and ``PIP`` are unspecified, it will use whatever's in your ``PATH`` -- so activate your virtualenv first.

.. _wheel: http://wheel.readthedocs.org/en/latest/

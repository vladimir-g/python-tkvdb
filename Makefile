USE_CYTHON = 1
PYTHON = python

default: install ;

.PHONY: build install clean uninstall dist test

build:
	USE_CYTHON=$(USE_CYTHON) $(PYTHON) setup.py build_ext

install:
	USE_CYTHON=$(USE_CYTHON) $(PYTHON) -m pip install .

clean:
	$(RM) -r build dist src/*.egg-info
	$(RM) -r src/tkvdb/*.c
	find . -name __pycache__ -exec rm -r {} +

uninstall:
	$(PYTHON) -m pip uninstall python-tkvdb

dist:
	USE_CYTHON=$(USE_CYTHON) $(PYTHON) setup.py sdist bdist_wheel

test:
	$(PYTHON) -m unittest

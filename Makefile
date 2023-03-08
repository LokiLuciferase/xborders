.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

PACKAGE_NAME = xborders
DOCKER_LOCAL_NAME = xborders
DOCKER_TARGET = NULL
DOCKER_TAG = latest

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	flake8 $(PACKAGE_NAME) tests

format:
	black -S -l 100 $(PACKAGE_NAME) tests setup.py
	docformatter --wrap-summaries 100 --wrap-descriptions 100 --pre-summary-newline -i -r $(PACKAGE_NAME) tests setup.py

test: ## run tests quickly with the default Python
	pytest --cov=$(PACKAGE_NAME) tests
	coverage xml

tc-test:
	pytest --cov=$(PACKAGE_NAME) --typeguard-packages=$(PACKAGE_NAME) tests
	coverage xml

dl-tc-test:
	LONG_TESTS=true pytest --cov=$(PACKAGE_NAME) --typeguard-packages=$(PACKAGE_NAME) tests
	coverage xml

coverage: ## check code coverage quickly with the default Python
	coverage run --source $(PACKAGE_NAME) -m pytest
	coverage report -m
	coverage html
	coverage xml
	${BROWSER} htmlcov/index.html

pre-commit: ## run pre-commit hooks
	pre-commit run --all-files

docs-build:
	rm -f docs/$(PACKAGE_NAME).rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ $(PACKAGE_NAME)
	$(MAKE) -C docs clean
	$(MAKE) -C docs html

docs: docs-build ## generate Sphinx HTML documentation, including API docs
	${BROWSER} docs/_build/html/index.html

githash:  ## create git hash for current repo HEAD
	[ ! -z "`git status`" ] && echo `git describe --match=DONOTMATCH --always --abbrev=40 --dirty` > $(PACKAGE_NAME)/.githash || echo 'Could not write githash.'

install: clean githash  ## install the package to the active Python's site-packages
	pip install .

install-dev: clean githash  ## install for development
	pip install -r requirements/dev.txt
	pip install -r requirements/test.txt
	pip install -r requirements/prod.txt
	pip install .

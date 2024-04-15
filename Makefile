.DEFAULT_GOAL:=help
.ONESHELL:
VENV_EXISTS=$(shell python3 -c "if __import__('pathlib').Path('.venv/bin/activate').exists(): print('yes')")
VERSION := $(shell grep -m 1 current_version .bumpversion.cfg | tr -s ' ' | tr -d '"' | tr -d "'" | cut -d' ' -f3)
BUILD_DIR=dist
COLLECTOR_PACKAGE=sql-scripts
BASE_DIR=$(shell pwd)
 
.EXPORT_ALL_VARIABLES:

ifndef VERBOSE
.SILENT:
endif

REPO_INFO ?= $(shell git config --get remote.origin.url)
COMMIT_SHA ?= git-$(shell git rev-parse --short HEAD)

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: install
install:	 ## Install the project in dev mode.
	@if [ "$(VENV_EXISTS)" ]; then source .venv/bin/activate; fi
	@if [ ! "$(VENV_EXISTS)" ]; then python3 -m venv .venv && source .venv/bin/activate; fi
	.venv/bin/pip install -U wheel setuptools cython pip mypy sqlfluff && .venv/bin/pip install -U -r requirements.txt -r requirements-docs.txt
	@echo "=> Build environment installed successfully.  ** If you want to re-install or update, 'make install'"

.PHONY: clean 
clean: clean-sqlscripts      ## remove all build, testing, and static documentation files
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +
	find . -name '.ipynb_checkpoints' -exec rm -fr {} +
	rm -fr .tox/
	rm -fr .coverage
	rm -fr coverage.xml
	rm -fr coverage.json
	rm -fr htmlcov/
	rm -fr .pytest_cache
	rm -fr .mypy_cache
	rm -fr site
	@echo "=> Source cleaned successfully"

.PHONY: clean-sqlscripts
clean-sqlscripts:
	@echo  "=> Cleaning previous build artifacts for sql scripts..."
	@rm -Rf $(BUILD_DIR)/collector/*

.PHONY: build-sqlscripts
build-sqlscripts: clean-sqlscripts      ## Build the collector SQL scripts.
	@rm -rf ./$(BUILD_DIR)/collector
	python3 -c "import m2r; python_text = m2r.convert(open('README.md').read()); f = open('README.txt', 'w'); f.write(python_text); f.close()"
	@echo "=> Building SQL Helper Scripts for Oracle version $(VERSION)..."
	python3 -c "import m2r; python_text = m2r.convert(open('oracle/README.md').read()); f = open('oracle/README.txt', 'w'); f.write(python_text); f.close()"
	@mkdir -p $(BUILD_DIR)/oracle
	@cp oracle/*.sql $(BUILD_DIR)/sqlscripts/oracle
	@cp  LICENSE $(BUILD_DIR)/sqlscripts/oracle
	echo "SQL Helper Scripts for Oracle Database version $(VERSION) ($(COMMIT_SHA))" > $(BUILD_DIR)/sqlscripts/oracle/VERSION.txt
	
	@echo "=> Building SQL Helper Scripts for Microsoft SQL Server version $(VERSION)..."
	python3 -c "import m2r; python_text = m2r.convert(open('mssql/README.md').read()); f = open('mssql/README.txt', 'w'); f.write(python_text); f.close()"
	@mkdir -p $(BUILD_DIR)/sqlscripts/sqlserver
	@cp mssql/*.sql $(BUILD_DIR)/sqlscripts/sqlserver
	@cp mssql/README.txt $(BUILD_DIR)/sqlscripts/sqlserver
	@cp LICENSE $(BUILD_DIR)/sqlscripts/sqlserver
	@echo "SQL Helper Scripts for Microsoft SQL Server version $(VERSION) ($(COMMIT_SHA))" > $(BUILD_DIR)/sqlscripts/sqlserver/VERSION.txt

	@echo "=> Building SQL Helper Scripts for Postgresql version $(VERSION)..."
	python3 -c "import m2r; python_text = m2r.convert(open('postgres/README.md').read()); f = open('postgres/README.txt', 'w'); f.write(python_text); f.close()"
	@mkdir -p $(BUILD_DIR)/sqlscripts/postgres
	@cp postgres/*.sql $(BUILD_DIR)/sqlscripts/postgres
	@cp postgres/README.txt $(BUILD_DIR)/sqlscripts/postgres
	@cp  LICENSE $(BUILD_DIR)/sqlscripts/postgres
	@echo "SQL Helper Scripts for Postgres version $(VERSION) ($(COMMIT_SHA))" > $(BUILD_DIR)/sqlscripts/postgres/VERSION.txt

	@make package-sqlscripts

.PHONY: package-sqlscripts
package-sqlscripts:
	@rm -f ./$(BUILD_DIR)/$(COLLECTOR_PACKAGE)*.bz2
	@rm -f ./$(BUILD_DIR)/$(COLLECTOR_PACKAGE)*.zip

	@echo  "=> Packaging SQL Scripts for Oracle..."
	@echo "Zipping files in ./$(BUILD_DIR)/sqlscripts/oracle"
	@cd $(BASE_DIR)/$(BUILD_DIR)/sqlscripts/oracle; zip -r $(BASE_DIR)/$(BUILD_DIR)/$(COLLECTOR_PACKAGE)-oracle.zip  *

	@echo  "=> Packaging SQL Scripts for Microsoft SQL Server..."
	@echo "Zipping files in ./$(BUILD_DIR)/sqlscripts/sqlserver"
	@cd $(BASE_DIR)/$(BUILD_DIR)/sqlscripts/sqlserver; zip -r $(BASE_DIR)/$(BUILD_DIR)/$(COLLECTOR_PACKAGE)-sqlserver.zip  *
	
	@echo  "=> Packaging SQL Scripts for Postgres..."
	@echo "Zipping files in ./$(BUILD_DIR)/sqlscripts/postgres"
	@cd $(BASE_DIR)/$(BUILD_DIR)/sqlscripts/postgres; zip -r $(BASE_DIR)/$(BUILD_DIR)/$(COLLECTOR_PACKAGE)-postgres.zip  *

.PHONY: build
build: build-sqlscripts        ## Build and package the collectors


###############
# docs        #
###############
.PHONY: doc-privs
doc-privs:   ## Extract the list of privileges required from code and create the documentation
	cat > docs/user_guide/oracle/permissions.md <<EOF
	# Create a user for Collection
	
	 The collection scripts can be executed with any DBA account. Alternatively, create a new user with the minimum privileges required.
	 The included script sql/setup/grants_wrapper.sql will grant the privileges listed below.
	 Please see the Database User Scripts page for information on how to create the user.
	
	## Permissions Required
	
	The following permissions are required for the script execution:
	
	 EOF
	 grep "rectype_(" scripts/collector/oracle/sql/setup/grants_wrapper.sql | grep -v FUNCTION | sed "s/rectype_(//g;s/),//g;s/)//g;s/'//g;s/,/ ON /1;s/,/./g" >> docs/user_guide/oracle/permissions.md

.PHONY: gen-docs
gen-docs:       ## generate HTML documentation
	./.venv/bin/mkdocs build

.PHONY: docs
docs:       ## generate HTML documentation and serve it to the browser
	./.venv/bin/mkdocs build
	./.venv/bin/mkdocs serve

.PHONY: pre-release
pre-release:       ## bump the version and create the release tag
	make gen-docs
	make clean
	./.venv/bin/bump2version $(increment)
	head .bumpversion.cfg | grep ^current_version
	make build
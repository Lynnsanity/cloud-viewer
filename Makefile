SHELL := /bin/bash

.PHONY: help
help:
	@printf "available targets -->\n\n"
	@cat Makefile | grep ".PHONY" | grep -v ".PHONY: _" | sed 's/.PHONY: //g'

.PHONY: root-project
root-project:
	gcloud config set project <ur-most-powerful-project-id-here>

.PHONY: report-directories
report-directories:
	mkdir -p ./reports
	mkdir -p ./reports/gcp

.PHONY: requirements
requirements:
	./env/bin/pip install -r requirements.txt

.PHONY: env
env:
	pyenv local 3.11
	python3 --version
	python3 -m venv env

.PHONY: gcp-report
gcp-report:
	./gcp-info.sh

.PHONY: update-gcp-sheet
update-gcp-sheet:
	python3 update_gcp_sheet.py


PYTHON ?= python3
PIP ?= $(PYTHON) -m pip

.PHONY: install format lint typecheck test docker-build terraform-fmt terraform-validate

install:
	$(PIP) install -r requirements.txt -r requirements-dev.txt

format:
	black app tests

lint:
	flake8 app tests

typecheck:
	mypy app

test:
	pytest tests

docker-build:
	docker build -f deploy/Dockerfile -t gcp-engineer-agent-mcp:local .

terraform-fmt:
	terraform -chdir=terraform fmt -recursive

terraform-validate:
	terraform -chdir=terraform validate

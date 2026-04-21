.PHONY: localstack-check localstack-start localstack-stop localstack-logs localstack-status localstack-start-legacy terraform-init terraform-plan terraform-apply terraform-destroy

LOCALSTACK_CONTAINER ?= localstack-main
LOCALSTACK_IMAGE ?= localstack/localstack:latest
LOCALSTACK_AUTH_TOKEN ?= ls-YuNE7033-KujO-tApe-WuPO-HoTo37910673
TERRAFORM_IMAGE ?= hashicorp/terraform:1.8.5

ifeq ($(OS),Windows_NT)
PWD_MOUNT := $(shell powershell -NoProfile -Command "(Get-Location).Path")

localstack-check:
	@powershell -NoProfile -Command "Write-Host '== DOCKER CLIENT =='; docker version --format 'Client {{.Client.Version}}'; Write-Host ''; Write-Host '== DOCKER SERVER =='; docker version --format 'Server {{.Server.Version}}'; Write-Host ''; Write-Host '== LOCALSTACK_AUTH_TOKEN =='; if ('$(TOKEN)' -or '$(LOCALSTACK_AUTH_TOKEN)' -or $$env:LOCALSTACK_AUTH_TOKEN) { Write-Host 'present' } else { Write-Host 'missing' }"

localstack-start:
	@powershell -NoProfile -Command "$$token='$(TOKEN)'; if (-not $$token) { $$token='$(LOCALSTACK_AUTH_TOKEN)' }; if (-not $$token) { $$token=$$env:LOCALSTACK_AUTH_TOKEN }; if (-not $$token) { Write-Host 'Missing token. Use: make localstack-start TOKEN=your_token or set LOCALSTACK_AUTH_TOKEN'; exit 1 }; docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e LOCALSTACK_AUTH_TOKEN=$$token -e AWS_DEFAULT_REGION=eu-west-1 -e SERVICES=s3,sqs,sns,dynamodb,lambda,iam,logs,cloudwatch -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; docker logs -n 40 $(LOCALSTACK_CONTAINER)"

localstack-start-legacy:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=eu-west-1 -e SERVICES=s3,sqs,sns,dynamodb,lambda,iam,logs,cloudwatch -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack:2.3 | Out-Null; docker logs -n 40 $(LOCALSTACK_CONTAINER)"

localstack-stop:
	@docker rm -f $(LOCALSTACK_CONTAINER)

localstack-logs:
	@docker logs -f $(LOCALSTACK_CONTAINER)

localstack-status:
	@docker ps --filter name=$(LOCALSTACK_CONTAINER)

terraform-init:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init

terraform-plan:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) plan

terraform-apply:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve

terraform-destroy:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) destroy -auto-approve

else
PWD_MOUNT := $(CURDIR)

localstack-check:
	@echo "== DOCKER CLIENT =="
	@docker version --format 'Client {{.Client.Version}}'
	@echo
	@echo "== DOCKER SERVER =="
	@docker version --format 'Server {{.Server.Version}}'
	@echo
	@echo "== LOCALSTACK_AUTH_TOKEN =="
	@if [ -n "$(TOKEN)" ] || [ -n "$(LOCALSTACK_AUTH_TOKEN)" ] || [ -n "$$LOCALSTACK_AUTH_TOKEN" ]; then echo "present"; else echo "missing"; fi

localstack-start:
	@token="$(TOKEN)"; \
	if [ -z "$$token" ]; then token="$(LOCALSTACK_AUTH_TOKEN)"; fi; \
	if [ -z "$$token" ]; then token="$$LOCALSTACK_AUTH_TOKEN"; fi; \
	if [ -z "$$token" ]; then echo "Missing token. Use: make localstack-start TOKEN=your_token or set LOCALSTACK_AUTH_TOKEN"; exit 1; fi; \
	docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true; \
	docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e LOCALSTACK_AUTH_TOKEN="$$token" -e AWS_DEFAULT_REGION=eu-west-1 -e SERVICES=s3,sqs,sns,dynamodb,lambda,iam,logs,cloudwatch -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null; \
	docker logs -n 40 $(LOCALSTACK_CONTAINER)

localstack-start-legacy:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=eu-west-1 -e SERVICES=s3,sqs,sns,dynamodb,lambda,iam,logs,cloudwatch -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack:2.3 >/dev/null
	@docker logs -n 40 $(LOCALSTACK_CONTAINER)

localstack-stop:
	@docker rm -f $(LOCALSTACK_CONTAINER)

localstack-logs:
	@docker logs -f $(LOCALSTACK_CONTAINER)

localstack-status:
	@docker ps --filter name=$(LOCALSTACK_CONTAINER)

terraform-init:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init

terraform-plan:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) plan

terraform-apply:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve

terraform-destroy:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) destroy -auto-approve
endif
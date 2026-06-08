.PHONY: up localstack-start localstack-stop localstack-status terraform-init terraform-plan terraform-apply terraform-destroy api-url api-test logs

LOCALSTACK_CONTAINER ?= localstack-main
LOCALSTACK_IMAGE ?= localstack/localstack:3.8.1
SERVICES ?= s3,dynamodb,iam,logs,sts,lambda,apigateway
TERRAFORM_IMAGE ?= hashicorp/terraform:1.8.5

ifeq ($(OS),Windows_NT)
PWD_MOUNT := $(shell powershell -NoProfile -Command "(Get-Location).Path")

localstack-start:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; docker logs -n 30 $(LOCALSTACK_CONTAINER)"

# Tout-en-un : demarre LocalStack, attend qu'il soit pret, puis init + apply
up:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; Write-Host 'Attente de LocalStack...'; $$ok=$$false; for($$i=0;$$i -lt 40;$$i++){ try { $$h=Invoke-RestMethod 'http://localhost:4566/_localstack/health' -TimeoutSec 3; if($$h.services.lambda -and $$h.services.apigateway){$$ok=$$true;break} } catch {}; Start-Sleep 2 }; if(-not $$ok){ Write-Host 'ERREUR: LocalStack non pret'; exit 1 }; Write-Host 'LocalStack pret.'"
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@powershell -NoProfile -Command "Write-Host ''; Write-Host 'API deployee. URL de base (a coller dans le front) :'; $$u=(docker run --rm -v '$(PWD_MOUNT):/workspace' -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url); Write-Host $$u"

api-test:
	@powershell -NoProfile -Command "$$u=(docker run --rm -v \"$(PWD_MOUNT):/workspace\" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url); Write-Host \"== GET $$u/hello?nom=Alice ==\"; (Invoke-WebRequest -UseBasicParsing \"$$u/hello?nom=Alice\").Content; Write-Host \"`n== POST $$u/users ==\"; (Invoke-WebRequest -UseBasicParsing -Method Post -ContentType application/json -Body '{\"nom\":\"Alice Dupont\",\"email\":\"alice@exemple.fr\"}' \"$$u/users\").Content; Write-Host \"`n== GET $$u/users ==\"; (Invoke-WebRequest -UseBasicParsing \"$$u/users\").Content"

else
PWD_MOUNT := $(CURDIR)

localstack-start:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null
	@docker logs -n 30 $(LOCALSTACK_CONTAINER)

# Tout-en-un : demarre LocalStack, attend qu'il soit pret, puis init + apply
up:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null
	@echo "Attente de LocalStack..."
	@for i in $$(seq 1 40); do curl -s http://localhost:4566/_localstack/health | grep -Eq 'apigateway"[: ]+"available' && break; sleep 2; done
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@echo "API deployee. URL de base (a coller dans le front) :"
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url
	@echo ""

api-test:
	@u=$$(docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url); \
	echo "== GET $$u/hello?nom=Alice =="; curl -s "$$u/hello?nom=Alice"; echo; \
	echo "== POST $$u/users =="; curl -s -X POST -H 'Content-Type: application/json' -d '{"nom":"Alice Dupont","email":"alice@exemple.fr"}' "$$u/users"; echo; \
	echo "== GET $$u/users =="; curl -s "$$u/users"; echo

endif

localstack-stop:
	@docker rm -f $(LOCALSTACK_CONTAINER)

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

api-url:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url

logs:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal logs describe-log-groups

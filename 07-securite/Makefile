.PHONY: up localstack-start localstack-stop terraform-init terraform-plan terraform-apply terraform-destroy verify

LOCALSTACK_CONTAINER ?= localstack-main
LOCALSTACK_IMAGE ?= localstack/localstack:3.8.1
SERVICES ?= kms,iam,s3,sts,logs,sns,cloudwatch,ec2
TERRAFORM_IMAGE ?= hashicorp/terraform:1.8.5

ifeq ($(OS),Windows_NT)
PWD_MOUNT := $(shell powershell -NoProfile -Command "(Get-Location).Path")

localstack-start:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; docker logs -n 30 $(LOCALSTACK_CONTAINER)"

up:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; Write-Host 'Attente de LocalStack...'; $$ok=$$false; for($$i=0;$$i -lt 40;$$i++){ try { $$h=Invoke-RestMethod 'http://localhost:4566/_localstack/health' -TimeoutSec 3; if($$h.services.kms -and $$h.services.sns){$$ok=$$true;break} } catch {}; Start-Sleep 2 }; if(-not $$ok){ Write-Host 'ERREUR: LocalStack non pret'; exit 1 }; Write-Host 'LocalStack pret.'"
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve

else
PWD_MOUNT := $(CURDIR)

localstack-start:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null
	@docker logs -n 30 $(LOCALSTACK_CONTAINER)

up:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null
	@echo "Attente de LocalStack..."
	@for i in $$(seq 1 40); do curl -s http://localhost:4566/_localstack/health | grep -Eq 'kms"[: ]+"(available|running)' && break; sleep 2; done
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve

endif

localstack-stop:
	@docker rm -f $(LOCALSTACK_CONTAINER)

terraform-init:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init

terraform-plan:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) plan

terraform-apply:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve

terraform-destroy:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) destroy -auto-approve

# Verifie les 5 piliers
verify:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal kms list-aliases --query "Aliases[?AliasName=='alias/app-securisee']"
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-roles --query "Roles[?RoleName=='app-backend-role'].RoleName"
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal sns list-topics
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal logs describe-log-groups --query "logGroups[].logGroupName"
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal cloudwatch describe-alarms --query "MetricAlarms[].AlarmName"

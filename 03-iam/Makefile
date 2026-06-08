.PHONY: up localstack-start localstack-stop terraform-init terraform-plan terraform-apply terraform-destroy verify policy simulate

LOCALSTACK_CONTAINER ?= localstack-main
LOCALSTACK_IMAGE ?= localstack/localstack:3.8.1
SERVICES ?= iam,sts,logs
TERRAFORM_IMAGE ?= hashicorp/terraform:1.8.5

ifeq ($(OS),Windows_NT)
PWD_MOUNT := $(shell powershell -NoProfile -Command "(Get-Location).Path")

localstack-start:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; docker logs -n 30 $(LOCALSTACK_CONTAINER)"

# Tout-en-un : demarre LocalStack, attend qu'il soit pret, puis init + apply
up:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; Write-Host 'Attente de LocalStack...'; $$ok=$$false; for($$i=0;$$i -lt 40;$$i++){ try { $$h=Invoke-RestMethod 'http://localhost:4566/_localstack/health' -TimeoutSec 3; if($$h.services.iam){$$ok=$$true;break} } catch {}; Start-Sleep 2 }; if(-not $$ok){ Write-Host 'ERREUR: LocalStack non pret'; exit 1 }; Write-Host 'LocalStack pret.'"
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
	@for i in $$(seq 1 40); do curl -s http://localhost:4566/_localstack/health | grep -Eq 'iam"[: ]+"(available|running)' && break; sleep 2; done
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

# Verifie l'utilisateur, son groupe et la policy attachee
verify:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-users
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-groups-for-user --user-name collegue-dupont
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-attached-group-policies --group-name developers

# Affiche la policy reelle (Allow EC2 + Deny IAM/S3/KMS) — marche sur LocalStack
policy:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam get-policy-version --policy-arn arn:aws:iam::000000000000:policy/DevEC2LimitedPolicy --version-id v1 --query "PolicyVersion.Document"

# Teste l'evaluation des permissions — NON supporte par LocalStack Community
# (fonctionne sur un vrai AWS). Sortie attendue : EC2=allowed, S3/IAM=denied.
simulate:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam simulate-principal-policy --policy-source-arn arn:aws:iam::000000000000:user/collegue-dupont --action-names ec2:RunInstances s3:GetObject iam:CreateUser

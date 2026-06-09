.PHONY: up down faas-url faas-test iam-verify iam-policy benchmark storage-verify s3-audit scaling-validate localstack-check localstack-start localstack-start-pro localstack-stop localstack-logs localstack-status localstack-start-legacy terraform-init terraform-plan terraform-apply terraform-destroy terraform-deploy terraform-deploy-plan terraform-deploy-destroy aws-tables aws-users aws-buckets aws-files aws-iam aws-logs aws-verify app-run

LOCALSTACK_CONTAINER ?= localstack-main
LOCALSTACK_IMAGE ?= localstack/localstack:3.8.1
LOCALSTACK_PRO_IMAGE ?= localstack/localstack:latest
LOCALSTACK_AUTH_TOKEN ?=
SERVICES ?= s3,dynamodb,iam,logs,sts,lambda,apigateway,ec2
TERRAFORM_IMAGE ?= hashicorp/terraform:1.8.5
PYTHON_IMAGE ?= python:3.11-slim

ifeq ($(OS),Windows_NT)
PWD_MOUNT := $(shell powershell -NoProfile -Command "(Get-Location).Path")
FAAS_MOUNT := $(PWD_MOUNT)\02-faas
IAM_MOUNT := $(PWD_MOUNT)\03-iam
STORAGE_MOUNT := $(PWD_MOUNT)\04-stockage
VULN_MOUNT := $(PWD_MOUNT)\05-vulnerabilite
SCALING_MOUNT := $(PWD_MOUNT)\06-scaling

localstack-check:
	@powershell -NoProfile -Command "Write-Host '== DOCKER CLIENT =='; docker version --format 'Client {{.Client.Version}}'; Write-Host ''; Write-Host '== DOCKER SERVER =='; docker version --format 'Server {{.Server.Version}}'; Write-Host ''; Write-Host '== LOCALSTACK_AUTH_TOKEN =='; if ('$(TOKEN)' -or '$(LOCALSTACK_AUTH_TOKEN)' -or $$env:LOCALSTACK_AUTH_TOKEN) { Write-Host 'present' } else { Write-Host 'missing' }"

localstack-start:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; docker logs -n 40 $(LOCALSTACK_CONTAINER)"

localstack-start-pro:
	@powershell -NoProfile -Command "$$token='$(TOKEN)'; if (-not $$token) { $$token='$(LOCALSTACK_AUTH_TOKEN)' }; if (-not $$token) { $$token=$$env:LOCALSTACK_AUTH_TOKEN }; if (-not $$token) { Write-Host 'Missing token. Use: make localstack-start-pro TOKEN=your_token or set LOCALSTACK_AUTH_TOKEN'; exit 1 }; docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e LOCALSTACK_AUTH_TOKEN=$$token -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_PRO_IMAGE) | Out-Null; docker logs -n 40 $(LOCALSTACK_CONTAINER)"

localstack-start-legacy:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=s3,sqs,sns,dynamodb,lambda,iam,logs,cloudwatch,apigateway -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack:2.3 | Out-Null; docker logs -n 40 $(LOCALSTACK_CONTAINER)"

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

terraform-deploy-plan:
	@powershell -NoProfile -Command "$$awsdir=Join-Path $$env:USERPROFILE '.aws'; if (-not (Test-Path $$awsdir)) { Write-Host 'Missing ~/.aws. Run: aws configure'; exit 1 }; docker run --rm -v \"$(PWD_MOUNT):/workspace\" -v \"$${awsdir}:/root/.aws:ro\" -e AWS_PROFILE=$${env:AWS_PROFILE} -w /workspace $(TERRAFORM_IMAGE) plan -var=use_localstack=false -state=terraform.prod.tfstate"

terraform-deploy:
	@powershell -NoProfile -Command "$$awsdir=Join-Path $$env:USERPROFILE '.aws'; if (-not (Test-Path $$awsdir)) { Write-Host 'Missing ~/.aws. Run: aws configure'; exit 1 }; docker run --rm -v \"$(PWD_MOUNT):/workspace\" -v \"$${awsdir}:/root/.aws:ro\" -e AWS_PROFILE=$${env:AWS_PROFILE} -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve -var=use_localstack=false -state=terraform.prod.tfstate"

terraform-deploy-destroy:
	@powershell -NoProfile -Command "$$awsdir=Join-Path $$env:USERPROFILE '.aws'; if (-not (Test-Path $$awsdir)) { Write-Host 'Missing ~/.aws. Run: aws configure'; exit 1 }; docker run --rm -v \"$(PWD_MOUNT):/workspace\" -v \"$${awsdir}:/root/.aws:ro\" -e AWS_PROFILE=$${env:AWS_PROFILE} -w /workspace $(TERRAFORM_IMAGE) destroy -auto-approve -var=use_localstack=false -state=terraform.prod.tfstate"

aws-tables:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal dynamodb list-tables

aws-users:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal dynamodb scan --table-name baas-users

aws-buckets:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls

aws-files:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls s3://baas-user-files --recursive

aws-iam:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-users

aws-logs:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal logs describe-log-groups

aws-verify:
	@powershell -NoProfile -Command "Write-Host '== DynamoDB tables =='; docker exec -t $(LOCALSTACK_CONTAINER) awslocal dynamodb list-tables; Write-Host '== S3 buckets =='; docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls; Write-Host '== IAM users =='; docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-users; Write-Host '== CloudWatch log groups =='; docker exec -t $(LOCALSTACK_CONTAINER) awslocal logs describe-log-groups"

app-run:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace -e AWS_ENDPOINT_URL=http://host.docker.internal:4566 $(PYTHON_IMAGE) sh -c "pip install --quiet boto3 && python app.py"

# Tout-en-un : LocalStack (tous services) + deploie BaaS (racine) + FaaS (02-faas)
up:
	@powershell -NoProfile -Command "docker rm -f $(LOCALSTACK_CONTAINER) 2>$$null | Out-Null; docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) | Out-Null; Write-Host 'Attente de LocalStack...'; $$ok=$$false; for($$i=0;$$i -lt 40;$$i++){ try { $$h=Invoke-RestMethod 'http://localhost:4566/_localstack/health' -TimeoutSec 3; if($$h.services.lambda -and $$h.services.apigateway -and $$h.services.dynamodb){$$ok=$$true;break} } catch {}; Start-Sleep 2 }; if(-not $$ok){ Write-Host 'ERREUR: LocalStack non pret'; exit 1 }; Write-Host 'LocalStack pret. Deploiement...'"
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(IAM_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(IAM_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(STORAGE_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(STORAGE_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(VULN_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(VULN_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@powershell -NoProfile -Command "Write-Host ''; Write-Host 'FaaS - URL de base (a coller dans le front) :'; $$u=(docker run --rm -v '$(FAAS_MOUNT):/workspace' -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url); Write-Host $$u"

faas-test:
	@powershell -NoProfile -Command "$$u=(docker run --rm -v '$(FAAS_MOUNT):/workspace' -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url); Write-Host \"== GET /hello ==\"; (Invoke-WebRequest -UseBasicParsing \"$$u/hello?nom=Alice\").Content; Write-Host \"`n== POST /users ==\"; (Invoke-WebRequest -UseBasicParsing -Method Post -ContentType application/json -Body '{\"nom\":\"Alice Dupont\",\"email\":\"alice@exemple.fr\"}' \"$$u/users\").Content; Write-Host \"`n== GET /users ==\"; (Invoke-WebRequest -UseBasicParsing \"$$u/users\").Content"

else
PWD_MOUNT := $(CURDIR)
FAAS_MOUNT := $(PWD_MOUNT)/02-faas
IAM_MOUNT := $(PWD_MOUNT)/03-iam
STORAGE_MOUNT := $(PWD_MOUNT)/04-stockage
VULN_MOUNT := $(PWD_MOUNT)/05-vulnerabilite
SCALING_MOUNT := $(PWD_MOUNT)/06-scaling

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
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null
	@docker logs -n 40 $(LOCALSTACK_CONTAINER)

localstack-start-pro:
	@token="$(TOKEN)"; \
	if [ -z "$$token" ]; then token="$(LOCALSTACK_AUTH_TOKEN)"; fi; \
	if [ -z "$$token" ]; then token="$$LOCALSTACK_AUTH_TOKEN"; fi; \
	if [ -z "$$token" ]; then echo "Missing token. Use: make localstack-start-pro TOKEN=your_token or set LOCALSTACK_AUTH_TOKEN"; exit 1; fi; \
	docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true; \
	docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e LOCALSTACK_AUTH_TOKEN="$$token" -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_PRO_IMAGE) >/dev/null; \
	docker logs -n 40 $(LOCALSTACK_CONTAINER)

localstack-start-legacy:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=s3,sqs,sns,dynamodb,lambda,iam,logs,cloudwatch,apigateway -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack:2.3 >/dev/null
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

terraform-deploy-plan:
	@if [ ! -d "$$HOME/.aws" ]; then echo "Missing ~/.aws. Run: aws configure"; exit 1; fi
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -v "$$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE="$$AWS_PROFILE" -w /workspace $(TERRAFORM_IMAGE) plan -var=use_localstack=false -state=terraform.prod.tfstate

terraform-deploy:
	@if [ ! -d "$$HOME/.aws" ]; then echo "Missing ~/.aws. Run: aws configure"; exit 1; fi
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -v "$$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE="$$AWS_PROFILE" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve -var=use_localstack=false -state=terraform.prod.tfstate

terraform-deploy-destroy:
	@if [ ! -d "$$HOME/.aws" ]; then echo "Missing ~/.aws. Run: aws configure"; exit 1; fi
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -v "$$HOME/.aws:/root/.aws:ro" -e AWS_PROFILE="$$AWS_PROFILE" -w /workspace $(TERRAFORM_IMAGE) destroy -auto-approve -var=use_localstack=false -state=terraform.prod.tfstate

aws-tables:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal dynamodb list-tables

aws-users:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal dynamodb scan --table-name baas-users

aws-buckets:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls

aws-files:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls s3://baas-user-files --recursive

aws-iam:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-users

aws-logs:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal logs describe-log-groups

aws-verify:
	@echo "== DynamoDB tables =="
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal dynamodb list-tables
	@echo "== S3 buckets =="
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls
	@echo "== IAM users =="
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-users
	@echo "== CloudWatch log groups =="
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal logs describe-log-groups

app-run:
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace -e AWS_ENDPOINT_URL=http://host.docker.internal:4566 $(PYTHON_IMAGE) sh -c "pip install --quiet boto3 && python app.py"

up:
	@docker rm -f $(LOCALSTACK_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d --name $(LOCALSTACK_CONTAINER) -p 4566:4566 -e AWS_DEFAULT_REGION=us-east-1 -e SERVICES=$(SERVICES) -e LAMBDA_DOCKER_NETWORK=bridge -v /var/run/docker.sock:/var/run/docker.sock $(LOCALSTACK_IMAGE) >/dev/null
	@echo "Attente de LocalStack..."
	@for i in $$(seq 1 40); do curl -s http://localhost:4566/_localstack/health | grep -Eq 'apigateway"[: ]+"available' && break; sleep 2; done
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(PWD_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(IAM_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(IAM_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(STORAGE_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(STORAGE_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@docker run --rm -v "$(VULN_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -input=false
	@docker run --rm -v "$(VULN_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve
	@echo "FaaS URL :"; docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url; echo ""

faas-test:
	@u=$$(docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url); \
	echo "== GET /hello =="; curl -s "$$u/hello?nom=Alice"; echo; \
	echo "== POST /users =="; curl -s -X POST -H 'Content-Type: application/json' -d '{"nom":"Alice Dupont","email":"alice@exemple.fr"}' "$$u/users"; echo; \
	echo "== GET /users =="; curl -s "$$u/users"; echo
endif

# --- Cibles communes (orchestration multi-projets) ---
down:
	@docker rm -f $(LOCALSTACK_CONTAINER)

faas-url:
	@docker run --rm -v "$(FAAS_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) output -raw invoke_url

iam-verify:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-users
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-groups-for-user --user-name collegue-dupont
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam list-attached-group-policies --group-name developers

iam-policy:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal iam get-policy-version --policy-arn arn:aws:iam::000000000000:policy/DevEC2LimitedPolicy --version-id v1 --query "PolicyVersion.Document"

benchmark:
	@docker run --rm -v "$(STORAGE_MOUNT):/workspace" -w /workspace -e AWS_ENDPOINT_URL=http://host.docker.internal:4566 $(PYTHON_IMAGE) sh -c "pip install --quiet boto3 && python benchmark.py"

storage-verify:
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal s3 ls
	@docker exec -t $(LOCALSTACK_CONTAINER) awslocal ec2 describe-volumes --query "Volumes[].{ID:VolumeId,Size:Size,Type:VolumeType}"

s3-audit:
	@docker run --rm -v "$(VULN_MOUNT):/workspace" -w /workspace -e AWS_ENDPOINT_URL=http://host.docker.internal:4566 $(PYTHON_IMAGE) sh -c "pip install --quiet boto3 && python audit.py"

# Projet 06 : Auto Scaling = LocalStack Pro/AWS reel. On valide juste la syntaxe.
scaling-validate:
	@docker run --rm -v "$(SCALING_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) init -backend=false -input=false
	@docker run --rm -v "$(SCALING_MOUNT):/workspace" -w /workspace $(TERRAFORM_IMAGE) validate
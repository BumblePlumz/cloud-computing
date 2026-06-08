# Déployer le BaaS

Ce mini-projet fonctionne en deux modes :
- **Dev** (LocalStack, par défaut) : `make terraform-apply`
- **Prod** (AWS réel) : `make terraform-deploy`

---

## 1. Mode dev — LocalStack

```bash
# Démarrer LocalStack (nécessite Docker)
make localstack-start TOKEN=<ton-token-localstack>
# ou sans token (image 2.3)
make localstack-start-legacy

# Déployer le BaaS
make terraform-init
make terraform-apply

# Lancer le client Python
python app.py

# Vérifier depuis awslocal
awslocal dynamodb scan --table-name baas-users
awslocal s3 ls s3://baas-user-files --recursive
awslocal logs describe-log-groups
```

Détruire tout :
```bash
make terraform-destroy
```

---

## 2. Mode prod — AWS réel

### 2.1 Pré-requis
- Un compte AWS (free tier suffit — cf section coûts)
- Docker Desktop (déjà nécessaire pour LocalStack)

### 2.2 Créer un utilisateur IAM de déploiement
On ne déploie **jamais** avec le compte root.

1. Console AWS → **IAM → Users → Create user**
2. Nom : `terraform-deploy`
3. Ne pas cocher l'accès console (on veut juste des clés API)
4. Attacher la policy **`AdministratorAccess`** (à restreindre plus tard à DynamoDB + S3 + IAM + Logs)
5. Créer l'utilisateur, puis **Security credentials → Create access key → CLI**
6. Copier `Access Key ID` et `Secret Access Key` (la secret n'est affichée qu'une fois)

### 2.3 Configurer les credentials locaux
Les targets `terraform-deploy*` montent `~/.aws` dans le container Terraform.

```bash
aws configure
# AWS Access Key ID:     <colle ta clé>
# AWS Secret Access Key: <colle ta secret>
# Default region:        us-east-1
# Default output format: json
```

Ou manuellement dans `~/.aws/credentials` + `~/.aws/config`. Sur Windows, `~` = `C:\Users\<user>`.

Vérifier :
```bash
aws sts get-caller-identity
```

### 2.4 Déployer
```bash
# Preview (aucune ressource créée)
make terraform-deploy-plan

# Apply
make terraform-deploy
```

Outputs renvoyés :
- `users_table` — nom de la table DynamoDB utilisateurs
- `sessions_table` — nom de la table DynamoDB sessions
- `files_bucket` — nom du bucket S3
- `baas_client_user` — utilisateur IAM client
- `log_group` — log group CloudWatch

### 2.5 Tester
Récupérer le nom du bucket :
```bash
docker run --rm -v "$(pwd):/workspace" -v "$HOME/.aws:/root/.aws:ro" \
  -w /workspace hashicorp/terraform:1.8.5 \
  output -state=terraform.prod.tfstate -raw files_bucket
```

Puis avec l'AWS CLI réel (pas `awslocal`) :
```bash
aws dynamodb scan --table-name baas-users
aws s3 ls s3://<files_bucket>/ --recursive
```

Pour pointer `app.py` sur AWS prod, supprime `endpoint_url` du dict `config` et utilise tes vrais credentials.

### 2.6 Détruire
```bash
make terraform-deploy-destroy
```
Vérifier dans la console AWS (DynamoDB, S3, IAM, CloudWatch) qu'il ne reste rien.

### 2.7 State file
Le déploiement prod utilise `terraform.prod.tfstate`, séparé du state LocalStack (`terraform.tfstate`). Les deux sont dans [.gitignore](.gitignore) — ne jamais les commiter (peuvent contenir des secrets).

---

## 3. Coûts attendus

Pour ce mini projet tu restes dans le **free tier** :

| Service | Free tier | Coût au-delà |
|---|---|---|
| DynamoDB (on-demand) | 25 GB storage (à vie) | $0.25 / GB / mois |
| S3 | 5 GB + 20k GET + 2k PUT (12 premiers mois) | $0.023 / GB / mois |
| CloudWatch Logs | 5 GB ingestion (à vie) | $0.50 / GB |
| IAM | gratuit | — |

Coût estimé d'un projet d'apprentissage : **0 €/mois**.

Détruis quand même par hygiène.

---

## 4. Résumé des commandes

| Commande | Effet |
|---|---|
| `make localstack-start` | Lance LocalStack (Docker) |
| `make localstack-stop` | Stoppe LocalStack |
| `make terraform-init` | Télécharge les providers (une fois) |
| `make terraform-plan` | Preview dev (LocalStack) |
| `make terraform-apply` | Apply dev (LocalStack) |
| `make terraform-destroy` | Destroy dev |
| `make terraform-deploy-plan` | Preview prod (AWS) |
| `make terraform-deploy` | Apply prod (AWS) |
| `make terraform-deploy-destroy` | Destroy prod |

# Cours — BaaS avec Terraform + LocalStack

> Support pédagogique pour le mini-projet 01 : déployer un Backend-as-a-Service localement en reproduisant l'architecture Firebase/Amplify avec DynamoDB, S3, IAM et CloudWatch.

---

## 1. Contexte et objectif

### 1.1 Qu'est-ce qu'un BaaS ?

Le **BaaS (Backend-as-a-Service)** est un modèle cloud où le fournisseur gère l'intégralité de l'infrastructure backend (base de données, authentification, stockage, notifications), laissant le développeur se concentrer uniquement sur le frontend et la logique métier.

| Tu gères | Le provider gère |
|---|---|
| Code frontend, logique métier, UI | Serveurs, base de données, scaling, sécurité infra, backups |

**Exemples réels** : Firebase (Google), AWS Amplify, Supabase, Appwrite.

**Avantages** : démarrage très rapide, pas d'ops à gérer, scaling automatique.
**Inconvénients** : moins de contrôle, vendor lock-in, coûts variables difficiles à prévoir.

### 1.2 Ce qu'on simule dans ce projet

On reproduit localement un BaaS minimal avec quatre briques AWS :

| Brique | Rôle BaaS | Équivalent Firebase |
|---|---|---|
| **DynamoDB** | Base NoSQL users + sessions | Firestore |
| **S3** | Stockage de fichiers utilisateurs | Cloud Storage |
| **IAM** | Identité et permissions d'accès | Firebase Auth (en partie) |
| **CloudWatch** | Logs et monitoring | Google Analytics for Firebase |

Tout tourne sur **LocalStack**, un émulateur AWS qui tourne en Docker — donc pas besoin de compte AWS pour apprendre.

---

## 2. Les notions techniques clés

### 2.1 Infrastructure as Code (IaC)

L'**IaC** consiste à décrire son infrastructure cloud dans des fichiers texte versionnés dans git, au lieu de cliquer dans une console web. Avantages :

- **Reproductible** : même stack chez tous les devs et en prod
- **Versionnée** : `git diff` montre qui a changé quoi
- **Testable** : `terraform plan` fait un dry-run avant tout déploiement

### 2.2 Terraform

**Terraform** (HashiCorp) est l'outil IaC de référence. Il lit des fichiers `.tf` (HCL — HashiCorp Configuration Language) et les compare avec l'état réel du cloud, puis applique le delta.

Les **4 commandes essentielles** :

```bash
terraform init      # Télécharge le provider AWS (1 fois par dossier)
terraform plan      # Dry-run : montre ce qui va être créé/modifié/détruit
terraform apply     # Applique les changements
terraform destroy   # Supprime tout ce que Terraform a créé
```

Fichier clé : `terraform.tfstate` — stocke l'état connu par Terraform. **Ne jamais commiter** ce fichier (peut contenir des secrets, et cause des conflits).

### 2.3 LocalStack

**LocalStack** émule les APIs AWS en local (dans un container Docker). Il écoute sur `http://localhost:4566` et répond à presque toutes les requêtes AWS, gratuitement et sans internet.

Pour pointer Terraform ou boto3 vers LocalStack au lieu d'AWS réel, on **override les endpoints** du provider :

```hcl
endpoints {
  dynamodb = "http://localhost:4566"
  s3       = "http://localhost:4566"
  iam      = "http://localhost:4566"
  logs     = "http://localhost:4566"
}
```

### 2.4 Les briques AWS utilisées

#### DynamoDB — base NoSQL
- Clé primaire (`hash_key`) obligatoire
- `billing_mode = "PAY_PER_REQUEST"` → pas besoin de provisionner de capacité (auto-scaling natif)
- **TTL** (Time To Live) : suppression automatique d'items après une date, via un attribut timestamp

#### S3 — stockage objet
- Organisé en **buckets** (nom globalement unique dans AWS réel)
- Chaque fichier = une **clé** (ex: `users/abc123/profil.txt`)
- **Versioning** : garde l'historique des versions d'un objet

#### IAM — Identity and Access Management
- **User** : identité (humain ou service)
- **Policy** : document JSON listant des permissions (`Allow`/`Deny` sur des `Action` et `Resource`)
- **ARN** (Amazon Resource Name) : identifiant unique d'une ressource, ex `arn:aws:s3:::baas-user-files`

#### CloudWatch Logs
- **Log Group** : conteneur logique de logs (ex `/baas/app`)
- **Log Stream** : flux de logs à l'intérieur d'un group
- **Retention** : durée avant suppression auto (7, 30, 365 jours…)

### 2.5 boto3 — SDK Python AWS

[boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) est le SDK officiel Python pour AWS. Dans notre `app.py` :

```python
dynamo = boto3.resource("dynamodb", endpoint_url="http://localhost:4566", ...)
s3     = boto3.client("s3",         endpoint_url="http://localhost:4566", ...)
```

`endpoint_url` est la clé qui fait pointer boto3 vers LocalStack au lieu d'AWS réel.

---

## 3. Lecture guidée du projet

### 3.1 Arborescence

```
.
├── main.tf          # Provider AWS (dual-mode LocalStack/prod)
├── dynamodb.tf      # 2 tables : users et sessions
├── s3.tf            # 1 bucket avec versioning
├── iam.tf           # User client + policy d'accès
├── cloudwatch.tf    # Log group /baas/app
├── outputs.tf       # Ressources exposées après apply
├── app.py           # Client Python simulant une app mobile
├── Makefile         # Wrappers Docker pour terraform + localstack
└── DEPLOY.md        # Guide dev (LocalStack) et prod (AWS)
```

### 3.2 Le pattern dual-mode dans [main.tf](main.tf)

```hcl
variable "use_localstack" {
  type    = bool
  default = true
}

provider "aws" {
  access_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      dynamodb = "http://host.docker.internal:4566"
      ...
    }
  }
}
```

- `dynamic "endpoints"` : bloc créé conditionnellement (présent si dev, absent si prod)
- `ternaire ? :` : choisit la valeur selon le booléen
- Basculer en prod : `terraform apply -var=use_localstack=false`

### 3.3 Exemple IAM — policy document

Dans [iam.tf](iam.tf), on utilise `aws_iam_policy_document` (data source) plutôt que du JSON brut :

```hcl
data "aws_iam_policy_document" "baas_client" {
  statement {
    sid       = "DynamoDBAccess"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", ...]
    resources = [aws_dynamodb_table.users.arn]
  }
}
```

Avantage : validation par Terraform, autocomplétion, refactoring plus simple qu'un gros bloc JSON.

---

## 4. Glossaire technique

| Terme | Définition |
|---|---|
| **ARN** | Amazon Resource Name. Identifiant unique d'une ressource AWS. Format : `arn:aws:service:region:account:resource`. |
| **BaaS** | Backend-as-a-Service. Fournit DB + auth + stockage + APIs sans coder le backend. |
| **Bucket (S3)** | Conteneur racine pour stocker des objets S3. Nom globalement unique sur AWS réel. |
| **CloudWatch** | Service AWS de logs, métriques et alarmes. |
| **Data source** (Terraform) | Ressource *lue* (pas créée), ex : récupérer l'ID d'une VPC existante. |
| **DynamoDB** | Base NoSQL serverless AWS (clé-valeur / document). |
| **Endpoint** | URL d'accès à un service AWS. Override utilisé pour pointer vers LocalStack. |
| **HCL** | HashiCorp Configuration Language. Syntaxe des fichiers `.tf`. |
| **IaC** | Infrastructure as Code. Infra décrite en fichiers versionnés. |
| **IAM** | Identity and Access Management. Gestion des identités et permissions AWS. |
| **LocalStack** | Émulateur AWS local en Docker, écoute sur port 4566. |
| **Policy (IAM)** | Document JSON listant des permissions (Allow/Deny). |
| **Provider** (Terraform) | Plugin qui traduit HCL en appels API (AWS, Azure, GCP…). |
| **Resource** (Terraform) | Bloc HCL décrivant une ressource à créer (ex `aws_s3_bucket`). |
| **TTL** (DynamoDB) | Time To Live. Attribut timestamp qui déclenche la suppression auto d'un item. |
| **tfstate** | Fichier d'état Terraform. Source de vérité de ce que Terraform a créé. |
| **Versioning** (S3) | Garde l'historique des versions d'un objet (restauration possible). |

---

## 5. Sources officielles

- **Terraform AWS Provider** — [registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **Terraform — Language** — [developer.hashicorp.com/terraform/language](https://developer.hashicorp.com/terraform/language)
- **LocalStack docs** — [docs.localstack.cloud](https://docs.localstack.cloud/)
- **LocalStack — AWS service coverage** — [docs.localstack.cloud/references/coverage](https://docs.localstack.cloud/references/coverage/)
- **AWS DynamoDB Developer Guide** — [docs.aws.amazon.com/dynamodb](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
- **AWS S3 User Guide** — [docs.aws.amazon.com/s3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/)
- **AWS IAM User Guide** — [docs.aws.amazon.com/iam](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
- **AWS CloudWatch Logs** — [docs.aws.amazon.com/cloudwatch/logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- **boto3 documentation** — [boto3.amazonaws.com](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
- **awscli-local (awslocal)** — [github.com/localstack/awscli-local](https://github.com/localstack/awscli-local)

---

## 6. Plan d'apprentissage

Objectif : passer de "je lance les commandes du TP" à "je comprends et je peux construire mon propre BaaS".

### Étape 1 — Fondations (≈ 2 h)

**Objectif** : savoir ce qu'est Terraform et comment il fonctionne.

- [ ] Lire [Terraform Introduction](https://developer.hashicorp.com/terraform/intro)
- [ ] Comprendre le cycle `init → plan → apply → destroy`
- [ ] Lancer le TP tel quel et observer `terraform.tfstate` après `apply`
- [ ] Modifier un tag sur `s3.tf`, relancer `plan`, lire le diff proposé

**Commandes à maîtriser** :
```bash
terraform init
terraform plan
terraform apply
terraform destroy
terraform show           # affiche l'état actuel
terraform state list     # liste les ressources gérées
terraform output         # affiche les outputs
```

### Étape 2 — Syntaxe HCL (≈ 3 h)

**Objectif** : lire et écrire du HCL sans copier-coller.

- [ ] Parcourir [Terraform Language Overview](https://developer.hashicorp.com/terraform/language)
- [ ] Étudier chaque bloc du projet : `resource`, `variable`, `locals`, `output`, `data`, `provider`
- [ ] Exercice : ajouter une 3ᵉ table DynamoDB `baas-messages` avec `hash_key = "messageId"` et `range_key = "createdAt"`
- [ ] Exercice : ajouter une variable `environment` (string, default `"dev"`) et l'injecter dans les tags de toutes les ressources

**Concepts clés** : `resource` vs `data`, interpolation `${}`, `for_each`, `dynamic`, ternaire `? :`.

### Étape 3 — Services AWS en profondeur (≈ 4 h)

**Objectif** : comprendre DynamoDB / S3 / IAM au-delà du TP.

- [ ] DynamoDB : lire [Core Components](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html) — clés primaires simples vs composites, GSI, LSI, capacity modes
- [ ] S3 : lire [Buckets overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingBucket.html) et [Object versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [ ] IAM : lire [Policy structure](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html) — Effect, Action, Resource, Condition
- [ ] Exercice : restreindre la policy S3 dans `iam.tf` pour qu'un user ne puisse accéder qu'à son propre préfixe `users/${aws:username}/*`

**Commandes à maîtriser** :
```bash
awslocal dynamodb scan --table-name baas-users
awslocal dynamodb query --table-name baas-users --key-condition-expression "userId = :id" --expression-attribute-values '{":id":{"S":"abc"}}'
awslocal s3 ls s3://baas-user-files --recursive
awslocal s3 cp ./local.txt s3://baas-user-files/test.txt
awslocal iam list-users
awslocal iam list-user-policies --user-name baas-client
awslocal logs describe-log-groups
```

### Étape 4 — LocalStack avancé (≈ 2 h)

**Objectif** : déboguer LocalStack quand ça plante.

- [ ] Lire [LocalStack configuration](https://docs.localstack.cloud/references/configuration/)
- [ ] Explorer le dashboard LocalStack (Pro) ou les logs : `make localstack-logs`
- [ ] Comprendre `SERVICES=...` et pourquoi certains services nécessitent la version Pro
- [ ] Exercice : démarrer LocalStack avec `DEBUG=1` et retracer une requête boto3 dans les logs

### Étape 5 — Python + boto3 (≈ 2 h)

**Objectif** : appeler les APIs AWS depuis du vrai code applicatif.

- [ ] Lire [boto3 Quickstart](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html)
- [ ] Différence entre `boto3.client()` (bas niveau) et `boto3.resource()` (haut niveau)
- [ ] Exercice : ajouter à `app.py` une fonction `creer_session(user_id)` qui écrit dans la table `baas-sessions` avec `expiresAt` = maintenant + 1 h
- [ ] Exercice : ajouter `generer_url_presignee(cle)` pour obtenir une URL S3 temporaire

### Étape 6 — Passer en prod sur AWS réel (≈ 3 h)

**Objectif** : déployer sur un vrai compte AWS.

- [ ] Suivre [DEPLOY.md](DEPLOY.md) section 2 : créer un user IAM `terraform-deploy`, configurer `~/.aws/credentials`
- [ ] Lancer `make terraform-deploy-plan` et lire le diff
- [ ] Appliquer avec `make terraform-deploy`
- [ ] Vérifier dans la console AWS (DynamoDB, S3, IAM, CloudWatch)
- [ ] **Important** : `make terraform-deploy-destroy` à la fin pour éviter des frais

### Étape 7 — Aller plus loin (optionnel)

- [ ] **Backend distant** : stocker le `tfstate` dans un bucket S3 avec lock DynamoDB ([docs backend S3](https://developer.hashicorp.com/terraform/language/settings/backends/s3))
- [ ] **Modules Terraform** : refactorer le projet en un module réutilisable
- [ ] **Workspaces** : gérer dev/staging/prod avec `terraform workspace`
- [ ] **CI/CD** : GitHub Actions qui lance `terraform plan` sur chaque PR
- [ ] **Ajouter Lambda + API Gateway** : transformer le BaaS en API REST complète
- [ ] **tfsec** ou **checkov** : scanner les configs Terraform pour vulnérabilités

---

## 7. Commandes de référence

### Terraform (via Docker, cf Makefile)
```bash
make terraform-init             # init dev
make terraform-plan             # plan dev (LocalStack)
make terraform-apply            # apply dev
make terraform-destroy          # destroy dev
make terraform-deploy-plan      # plan prod (AWS réel)
make terraform-deploy           # apply prod
make terraform-deploy-destroy   # destroy prod
```

### LocalStack
```bash
make localstack-start TOKEN=xxx # démarrer (version pro)
make localstack-start-legacy    # démarrer (version 2.3 gratuite)
make localstack-stop            # arrêter et supprimer le container
make localstack-logs            # suivre les logs
make localstack-status          # voir l'état du container
```

### awslocal (= aws CLI → LocalStack)
```bash
awslocal s3 ls
awslocal dynamodb list-tables
awslocal dynamodb scan --table-name baas-users
awslocal iam list-users
awslocal logs describe-log-groups
```

### Python client
```bash
python app.py                   # créer user + uploader fichier + lister
```

---

## 8. Checklist de validation du TP

- [ ] `terraform init` passe sans erreur
- [ ] `terraform apply` crée 2 tables DynamoDB, 1 bucket S3, 1 user IAM, 1 log group
- [ ] `terraform output` affiche les 5 ressources
- [ ] `python app.py` crée un user et upload un fichier sans erreur
- [ ] `awslocal dynamodb scan --table-name baas-users` montre le user créé
- [ ] `awslocal s3 ls s3://baas-user-files --recursive` montre le fichier uploadé
- [ ] `terraform destroy` nettoie tout
- [ ] Le `tfstate` n'est **pas** committé dans git (cf [.gitignore](.gitignore))

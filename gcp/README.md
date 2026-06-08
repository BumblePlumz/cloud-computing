# BaaS GCP — version parallèle du projet AWS

Ce dossier reproduit **exactement la même infra** que la racine (AWS/LocalStack),
mais avec les services GCP équivalents. Objectif : voir concrètement la
correspondance entre les deux clouds.

## Correspondance des ressources

| AWS (racine) | GCP (ici) | Fichier |
|---|---|---|
| `aws_dynamodb_table.users` + `.sessions` | `google_firestore_database.baas` + collections implicites | [firestore.tf](firestore.tf) |
| `aws_s3_bucket.user_files` | `google_storage_bucket.user_files` | [storage.tf](storage.tf) |
| `aws_iam_user.baas_client` | `google_service_account.baas_client` | [iam.tf](iam.tf) |
| `aws_iam_user_policy` | `google_*_iam_member` (rôles prédéfinis) | [iam.tf](iam.tf) |
| `aws_cloudwatch_log_group` | `google_logging_project_bucket_config` | [logging.tf](logging.tf) |

## Différences importantes à comprendre

| Concept | AWS | GCP |
|---|---|---|
| Base NoSQL | DynamoDB avec schéma de clés déclaré | Firestore 100% schemaless, collections à la volée |
| Auth machine | IAM user + access key + policy custom | Service account + clé JSON + rôles prédéfinis |
| Logs | "Log groups" créés explicitement | Logs auto par projet, on route avec des "log buckets" |
| Nom global | Buckets S3 globalement uniques | Buckets GCS globalement uniques aussi |

## Peut-on tester en local comme avec LocalStack ?

**Non, pas aussi simplement.** GCP n'a pas d'équivalent complet à LocalStack.
Il existe des émulateurs officiels **par service** :

- Firestore : `gcloud emulators firestore start` (officiel)
- Pub/Sub : `gcloud emulators pubsub start` (officiel)
- Cloud Storage : pas d'émulateur officiel, utiliser [fake-gcs-server](https://github.com/fsouza/fake-gcs-server) (tiers)
- IAM / Logging : pas d'émulateur

Pour ce TP, le plus simple est d'utiliser un vrai projet GCP en **free tier**.

## Déploiement sur GCP réel (free tier, 0€/mois)

### 1. Créer un projet GCP

1. Aller sur https://console.cloud.google.com
2. Créer un compte (demande une carte bancaire mais 90 jours × 300$ de crédit gratuit)
3. Créer un nouveau projet (note bien le **project ID**, ex: `mon-baas-123456`)
4. Activer les APIs nécessaires :
   ```bash
   gcloud services enable \
       firestore.googleapis.com \
       storage.googleapis.com \
       iam.googleapis.com \
       logging.googleapis.com \
       cloudresourcemanager.googleapis.com
   ```

### 2. Authentifier Terraform

Deux options :

**Option A — Application Default Credentials (plus simple en dev)**
```bash
gcloud auth application-default login
```

**Option B — Service account dédié au déploiement**
```bash
gcloud iam service-accounts create terraform-deploy
gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:terraform-deploy@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/owner"
gcloud iam service-accounts keys create key.json \
    --iam-account=terraform-deploy@<PROJECT_ID>.iam.gserviceaccount.com
```
Puis dans la commande Terraform : `-var=gcp_credentials_file=./key.json`

### 3. Deploy

```bash
cd gcp
terraform init
terraform plan -var="gcp_project=<PROJECT_ID>"
terraform apply -var="gcp_project=<PROJECT_ID>"
```

### 4. Récupérer la clé du service account client + variables pour app.py

```bash
# Sauver la clé JSON du service account client
terraform output -raw baas_client_credentials_json | base64 -d > baas-client-key.json

# Variables pour app.py
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/baas-client-key.json
export GCP_PROJECT=<PROJECT_ID>
export FILES_BUCKET=$(terraform output -raw files_bucket)

pip install google-cloud-firestore google-cloud-storage
python app.py
```

### 5. Vérifier côté console GCP

- Firestore : https://console.cloud.google.com/firestore/data
- Cloud Storage : https://console.cloud.google.com/storage/browser
- IAM : https://console.cloud.google.com/iam-admin/serviceaccounts
- Logs : https://console.cloud.google.com/logs

### 6. Détruire

```bash
terraform destroy -var="gcp_project=<PROJECT_ID>"
rm baas-client-key.json
```

## Coûts attendus

Tout ce qui est dans ce projet rentre dans le **free tier GCP** :

| Service | Free tier (à vie) | Coût au-delà |
|---|---|---|
| Firestore | 1 GiB storage, 50k reads/day, 20k writes/day | $0.18 / 100k reads |
| Cloud Storage | 5 GB storage, 5000 class-A ops/mois | $0.020 / GB / mois |
| Service accounts | gratuit | — |
| Cloud Logging | 50 GiB ingestion / mois | $0.50 / GiB |

**Coût estimé d'un projet d'apprentissage : 0 €/mois.**

Le compte demande une carte bancaire à la création mais rien n'est débité tant
que tu restes dans les limites gratuites. Détruis quand même la stack à la fin
(`terraform destroy`) par hygiène.

## Comparer les deux clients Python

Compare côte à côte [../app.py](../app.py) (AWS/boto3) et [./app.py](./app.py)
(GCP/google-cloud-*). Les APIs sont différentes mais le pattern est identique :
un client SDK qui parle directement aux services managés, signé en interne
avec des credentials. Aucun serveur HTTP custom au milieu.

# Mini-Projet 05 — Version GCP (bucket troué + corrigé)

Équivalent **Google Cloud Storage** du mini-projet 05 AWS. Même piège, vocabulaire différent.

> ⚠️ **Ne tourne PAS sur LocalStack** (qui n'émule pas GCP). Cible le **vrai Google Cloud** :
> il faut un projet GCP + des credentials pour `terraform apply`.

## Correspondance AWS ↔ GCP
| AWS (05-vulnerabilite) | GCP (ici) |
|---|---|
| `aws_s3_bucket_public_access_block` | `public_access_prevention` (`enforced`) |
| ACL `public-read` / policy `Principal:"*"` | IAM member **`allUsers`** |
| `BucketOwnerEnforced` (ACL désactivées) | `uniform_bucket_level_access = true` |
| `aws_s3_bucket_versioning` | bloc `versioning { enabled = true }` |
| Chiffrement par défaut (SSE-S3) | chiffrement par défaut (clés Google) / CMEK |

## Les failles (bucket vulnérable)
| Faille | Réglage fautif | Correction |
|--------|----------------|------------|
| Garde-fou public désactivé | `public_access_prevention = "inherited"` | `"enforced"` |
| ACL activées | `uniform_bucket_level_access = false` | `true` |
| Bucket public | IAM `member = "allUsers"` | retirer le binding |
| Pas de versioning | bloc absent | `versioning { enabled = true }` |

## Le point clé GCP
Sur GCS, rendre un bucket public = accorder un rôle de lecture à **`allUsers`**
(`allUsers` = anonymes) ou **`allAuthenticatedUsers`** (n'importe quel compte Google).
La parade maître est **Public Access Prevention** en mode `enforced` : il **bloque**
toute tentative de binding `allUsers`/`allAuthenticatedUsers`, même ajoutée par erreur —
exactement le rôle du Public Access Block côté AWS.

## Lancer (sur un vrai projet GCP)
```bash
terraform init
terraform apply -var="gcp_project=mon-projet-123456"
# (credentials via `gcloud auth application-default login` ou -var gcp_credentials_file=...)
terraform destroy -var="gcp_project=mon-projet-123456"
```

## Vérifier la posture
```bash
gcloud storage buckets describe gs://<projet>-bucket-securise-demo \
  --format="default(public_access_prevention, uniform_bucket_level_access)"
# Lister qui a accès (le vulnérable montrera allUsers) :
gcloud storage buckets get-iam-policy gs://<projet>-bucket-vulnerable-demo
```

# Mini-Projet 05 — Vulnérabilité S3 (bucket non sécurisé)

Approche **red team** : déployer un bucket **volontairement non sécurisé**, l'auditer,
puis montrer la version corrigée. **Ne JAMAIS reproduire sur un vrai compte AWS.**

## Les 2 buckets
| | `bucket-vulnerable-demo` | `bucket-securise-demo` |
|---|---|---|
| Public Access Block | ❌ tout ouvert | ✅ bloqué (4/4) |
| ACL | `public-read` | privée |
| Bucket Policy | `Principal: *` (public) | aucune policy publique |
| Versioning | ❌ absent | ✅ activé |
| Chiffrement | (par défaut AWS) | AES-256 |

## Fichiers
| Fichier | Rôle |
|---------|------|
| `main.tf` | Provider |
| `bucket_vulnerable.tf` | Bucket non sécurisé (6 oublis intentionnels) |
| `bucket_securise.tf` | Version corrigée |
| `audit.py` | Compare la posture de sécurité des 2 buckets (PASS/FAIL) |

## Lancer
```bash
make up      # déploie les 2 buckets
make audit   # rapport de sécurité comparatif
make terraform-destroy
```
Résultat : vulnérable **1/4**, sécurisé **4/4**.

## Les 6 failles & corrections
| Faille | Correction Terraform |
|--------|----------------------|
| Accès public non bloqué | `aws_s3_bucket_public_access_block` (tout à `true`) |
| ACL `public-read` | `acl = private` (défaut) |
| Policy `Principal: *` | restreindre à des ARN précis |
| Pas de chiffrement | `..._server_side_encryption_configuration` |
| Pas de versioning | `aws_s3_bucket_versioning` (`Enabled`) |
| Pas de logging | `aws_s3_bucket_logging` |

## ⚠️ Deux nuances (réalité actuelle)
1. **Chiffrement par défaut** : depuis 2023, AWS chiffre **tous** les buckets en SSE-S3 (AES256). Donc même le bucket « vulnérable » apparaît chiffré — la faille « pas de chiffrement » du cours est datée. Les vraies failles restantes (accès public, policy publique, pas de versioning) sont bien détectées.
2. **LocalStack n'évalue pas les policies S3** : on ne peut pas *vraiment* démontrer une lecture anonyme. L'audit lit la **configuration stockée** (ACL, policy, PAB, versioning) — c'est elle qui prouve la (mauvaise) posture.

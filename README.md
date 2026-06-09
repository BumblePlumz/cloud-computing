# Infrastructure as Code — 7 mini-projets Terraform (LocalStack)

Cours pratique **Cloud, Sécurité & Terraform**. Chaque mini-projet déploie une brique
d'infrastructure AWS sur **LocalStack** (Docker), sans compte cloud réel.

> 📂 Une version **GCP** parallèle existe dans `gcp/` (BaaS + bucket sécurisé) — cible le vrai Google Cloud.

## 🚀 Démarrage rapide (tout depuis la racine)
```bash
make up      # LocalStack + déploie 6 projets (01-05 + 07)
make down    # tout arrêter
```
Pré-requis : **Docker** + **make**. Le reste (Terraform, Python) tourne en conteneur.

## Les 7 mini-projets

| # | Projet | Dossier | Concept clé | Déployable en local ? |
|---|--------|---------|-------------|------------------------|
| 01 | **BaaS** | [racine](dynamodb.tf) | Backend managé (DynamoDB+S3+IAM) façon Firebase | ✅ |
| 02 | **FaaS** | [`02-faas/`](02-faas/) | Serverless : Lambda + API Gateway | ✅ |
| 03 | **IAM** | [`03-iam/`](03-iam/) | Moindre privilège, Deny explicite | ✅ |
| 04 | **Stockage** | [`04-stockage/`](04-stockage/) | Block (EBS) vs Object (S3) : perf & coûts | ✅ |
| 05 | **Vulnérabilité S3** | [`05-vulnerabilite/`](05-vulnerabilite/) | Bucket troué → corrigé (red team) | ✅ |
| 06 | **Scalabilité** | [`06-scaling/`](06-scaling/) | Auto Scaling Group + alarmes | ⚠️ validate (Pro/AWS) |
| 07 | **Sécurité + PRA** | [`07-securite/`](07-securite/) | 5 piliers + Plan de Reprise d'Activité | ✅ |

Chaque dossier a son **`README.md`** (théorie + commandes + limites + réflexe GCP).

## Ordre d'étude conseillé
1. **01 BaaS** → comprendre l'assemblage de services managés.
2. **02 FaaS** → la couche serverless + API (avec un front de démo dans `02-faas/front/`).
3. **03 IAM** → la sécurité des accès (le socle de tout le reste).
4. **04 Stockage** → l'arbitrage perf/coût.
5. **05 Vulnérabilité** → apprendre en attaquant.
6. **06 Scalabilité** → l'élasticité automatique.
7. **07 Sécurité + PRA** → la synthèse (défense en profondeur).

## Commandes par projet (depuis la racine)
| Commande | Projet |
|----------|--------|
| `make aws-verify` / `make app-run` | 01 BaaS |
| `make faas-test` / `make faas-url` | 02 FaaS |
| `make iam-verify` / `make iam-policy` | 03 IAM |
| `make benchmark` / `make storage-verify` | 04 Stockage |
| `make s3-audit` | 05 Vulnérabilité |
| `make scaling-validate` | 06 Scalabilité |
| `make sec-verify` | 07 Sécurité |

## Concepts clés à retenir
- **BaaS vs FaaS** : services gérés vs fonctions à la demande (zéro serveur).
- **IAM** : refuser par défaut, ouvrir au minimum, **Deny > Allow**.
- **Stockage** : Block = latence ultra-faible (BDD) ; Object = coût bas (fichiers).
- **Sécurité S3** : bloquer l'accès public, chiffrer, forcer HTTPS, versioning.
- **Scaling** : Auto Scaling Group = disponibilité + élasticité automatiques.
- **Défense en profondeur** : IAM + KMS + réseau + logs + backup empilés.
- **PRA** : RPO (perte de données acceptable) / RTO (temps de reprise) ; un PRA non testé ne vaut rien.

## Correspondances AWS ↔ GCP
| AWS | GCP |
|-----|-----|
| DynamoDB | Firestore / Datastore |
| S3 | Cloud Storage (GCS) |
| Lambda | Cloud Functions |
| API Gateway | API Gateway / Cloud Endpoints |
| IAM User + access key | Service Account + clé JSON |
| Policy JSON (Allow/Deny) | rôles (`roles/*`) via bindings |
| EBS | Persistent Disk |
| Public Access Block | Public Access Prevention |
| Auto Scaling Group | Managed Instance Group |
| KMS | Cloud KMS |

## ⚠️ Limites LocalStack Community (par design)
| Projet | Limite | Contournement |
|--------|--------|---------------|
| 03 | `simulate-principal-policy` non évalué | `make iam-policy` montre la policy |
| 04 | EBS = mock (non benchmarkable) | mesure « block » sur fichier local |
| 05 | policies S3 non évaluées | audit sur la config stockée |
| 06 | Auto Scaling = **Pro** | `terraform validate` seulement |
| 07 | AWS Backup / lifecycle S3 / dashboard | variables `enable_*` (false en local) |

## Architecture technique
- **LocalStack** (`localstack/localstack:3.8.1`, Community) dans un conteneur `localstack-main`.
- **Terraform** (`hashicorp/terraform:1.8.5`) et **Python** (`python:3.11-slim`) exécutés en conteneurs → rien à installer en local hormis Docker + make.
- Une **seule instance LocalStack** partagée par tous les projets ; états Terraform séparés par dossier.
- ⚠️ LocalStack est **éphémère** : après `make down` ou un redémarrage Docker, refaire `make up`.

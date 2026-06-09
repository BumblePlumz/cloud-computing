# Mini-Projet 07 — Application sécurisée + PRA (tout-en-un)

Reprend le BaaS et applique **5 piliers de sécurité** + un **Plan de Reprise d'Activité**.
C'est la **défense en profondeur** : plusieurs couches, pour que si l'une lâche, les autres tiennent.

## Les 5 piliers
| Pilier | Fichier | Contenu |
|--------|---------|---------|
| 1. IAM + KMS | `iam.tf` | clé KMS centrale (rotation), rôle backend moindre privilège + Deny admin |
| 2. Chiffrement | `encryption.tf` | S3 chiffré KMS, accès public bloqué, policy **HTTPS obligatoire** |
| 3. Réseau | `network.tf` | VPC, subnet privé, Security Group (443 entrant, interne sortant) |
| 4. Monitoring | `monitoring.tf` | log groups chiffrés, SNS, alarmes (erreurs, IAM denied), dashboard |
| 5. Backup + PRA | `backup.tf`, `restore.sh`, `PRA.md` | bucket backup versionné/chiffré, lifecycle, AWS Backup, plan de reprise |

## Lancer
```bash
make up       # déploie les piliers (Community : sans AWS Backup ni lifecycle)
make verify   # vérifie KMS, S3, IAM, SNS, logs, alarmes
make terraform-destroy
```

## ⚠️ Limites LocalStack Community (gérées par variables)
Deux éléments ne fonctionnent pas en Community, donc **désactivés par défaut** :
| Ressource | Variable | Pourquoi |
|-----------|----------|----------|
| AWS Backup (vault + plan) | `enable_aws_backup` | service **Pro** uniquement |
| Lifecycle S3 (IA→Glacier) | `enable_s3_lifecycle` | le provider attend une propagation jamais confirmée par LocalStack (timeout) |

Sur un **vrai AWS** (ou Pro) :
```bash
terraform apply -var=enable_aws_backup=true -var=enable_s3_lifecycle=true -var=use_localstack=false
```

## Plan de Reprise d'Activité
Voir **`PRA.md`** (RPO 1h / RTO 4h, scénarios, planning de tests) et **`restore.sh`**
(`s3-restore`, `infra-rebuild`, `network-lockdown`, `kms-rotation`).

> **Un PRA non testé ne vaut rien** — tester au minimum trimestriellement.

## À retenir
Sécurité complète = **IAM + KMS + Security Groups + Logs + Backup** = défense en profondeur.

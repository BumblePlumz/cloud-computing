# Mini-Projet 03 — IAM : accès sécurisés pour un collègue

Créer un accès IAM **au moindre privilège** : un collègue peut déployer des serveurs **EC2**,
mais ne peut **pas** toucher à **IAM**, **S3** ou **KMS**.

## Principe
```
User (collegue-dupont)  →  membre du Group (developers)  →  Policy (DevEC2LimitedPolicy)
                                                              Allow EC2 + logs
                                                              Deny  IAM / S3 / KMS  (explicite)
```

## Fichiers
| Fichier | Rôle |
|---------|------|
| `main.tf` | Provider AWS (LocalStack / AWS réel) |
| `iam.tf` | Group, Policy (Allow/Deny), User, appartenance, clés d'accès |
| `outputs.tf` | Access key, user, groupe, ARN de la policy |

## Lancer
```bash
make up          # LocalStack (iam) + init + apply
make verify      # user + groupe + policy attachée
make policy      # affiche la policy réelle (Allow EC2 / Deny IAM-S3-KMS)
make terraform-destroy
```

## Bonnes pratiques illustrées
- **Jamais de droits directement sur un User** → toujours via un **Group** (`aws_iam_group_policy_attachment`).
- **Deny explicite** sur les ressources critiques (IAM, KMS, S3) : un `Deny` l'emporte toujours sur un `Allow`.
- Un **`Sid`** dans chaque statement → auditabilité.
- Le **secret** de la clé d'accès est marqué `sensitive` (masqué dans les outputs).
- MFA pour les comptes humains (non simulable dans LocalStack).

## ⚠️ Limite LocalStack
`iam simulate-principal-policy` (l'évaluation des permissions du cours) **n'est pas supporté
par LocalStack Community** : l'IAM y stocke les policies mais ne les *évalue* pas. Sur un vrai
AWS, la commande renverrait `ec2:RunInstances = allowed`, `s3:GetObject = denied`.
Ici on prouve la config via `make policy` (la policy contient bien le Deny).

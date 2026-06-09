# Plan de Reprise d'Activité (PRA) — Mini-Projet 07

## 1. Périmètre et objectifs
| Paramètre | Valeur |
|-----------|--------|
| Application | BaaS sécurisée : DynamoDB + S3 + Lambda |
| **RPO** cible | 1 heure (perte de données max acceptable) |
| **RTO** cible | 4 heures (durée max avant remise en service) |
| Responsable | DevOps + DBA |
| Fréquence de revue | Semestrielle ou après tout incident |
| Outil de restauration | Terraform + `restore.sh` |

> **RPO** = combien de données on accepte de perdre. **RTO** = combien de temps on accepte d'être hors service.

## 2. Scénarios et procédures
| Scénario | RTO | RPO | Procédure |
|----------|-----|-----|-----------|
| Suppression accidentelle S3 | < 30 min | < 1 h | `list-object-versions` → `copy-object` (restaurer une version) |
| Corruption DynamoDB | < 2 h | < 1 h | Restaurer snapshot AWS Backup → valider → relancer |
| Clé KMS compromise | < 4 h | 0 | Disable → new key → re-chiffrer → update policies → audit |
| Intrusion réseau | < 1 h | 0 | Modifier Security Groups → invalider clés IAM → analyser CloudWatch → notifier RSSI |
| Panne totale infra | < 8 h | < 1 h | `terraform destroy` → `apply` → restaurer backup → update DNS |

## 3. Script automatisé
Voir `restore.sh` : `s3-restore`, `infra-rebuild`, `network-lockdown`, `kms-rotation`.

## 4. Plan de secours (fallback)
Si `terraform apply` échoue pendant la restauration :
1. Rollback vers la dernière version stable du code (`git checkout <tag>`)
2. Restaurer manuellement les ressources critiques via la CLI
3. Activer le mode maintenance (page statique S3)

Si la région est indisponible (prod AWS) :
1. Basculer vers la région secondaire (`terraform workspace select dr`)
2. Mettre à jour Route 53 vers la région secondaire
3. Notifier les utilisateurs

Contact d'urgence : DevOps → DBA → RSSI → Direction

## 5. Planning des tests PRA
| Test | Fréquence | Procédure |
|------|-----------|-----------|
| Restauration S3 | Mensuel | restaurer un fichier depuis une version précédente |
| Rebuild complet infra | Trimestriel | `destroy` + `apply`, mesurer le temps vs RTO 4 h |
| Simulation intrusion | Semestriel | IP malveillante, vérifier détection + lockdown |
| Exercice PRA complet | Annuel | perte totale simulée, chronométrer chaque étape |

> **Un PRA non testé ne vaut rien.** Tester au minimum trimestriellement.

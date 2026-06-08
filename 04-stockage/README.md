# Mini-Projet 04 — Stockage : Block vs Objet (perf & coûts)

Comprendre **quel stockage choisir** et **combien ça coûte**, en mesurant la différence.

## Les 2 familles comparées
| | **Block** (EBS / Persistent Disk) | **Object** (S3 / Cloud Storage) |
|---|---|---|
| Latence | < 1 ms | 10–100 ms |
| Accès | aléatoire, byte par byte | fichier entier (HTTP REST) |
| Modification | sur place | remplacer l'objet entier |
| Scalabilité | limitée à la VM | infinie |
| Coût ~1 To/mois | ~82 € (gp3) | ~23 € |

**Règle :** octets modifiés au milieu d'un fichier (BDD, OS) → **Block** ; fichiers entiers (médias, backups, logs) → **Object**.

## Fichiers
| Fichier | Rôle |
|---------|------|
| `main.tf` | Provider AWS (LocalStack / AWS réel) |
| `storage.tf` | Bucket S3 (object) + volume EBS (block) |
| `benchmark.py` | Mesure lecture/écriture S3 vs fichier local + calcul de coûts |
| `outputs.tf` | Bucket, volume EBS |

## Lancer
```bash
make up          # LocalStack (s3, ec2) + init + apply
make benchmark   # mesure perfs + affiche les coûts
make verify      # liste buckets + volumes
make terraform-destroy
```

## ⚠️ Limite LocalStack (à connaître)
LocalStack simule **S3** réellement, mais **EBS est un mock** : pas de vrai disque block attaché, donc non benchmarkable. Le `benchmark.py` mesure donc :
- **S3** → appels réels à LocalStack ✅
- **« Block »** → fichiers locaux (= ton SSD), pour illustrer l'ordre de grandeur

C'est un projet **démonstratif** : l'objectif est de comprendre l'arbitrage **perf vs coût**, pas de mesurer un vrai EBS. Résultat typique : le local est ~100–300× plus rapide en lecture que S3, mais S3 est ~3,5× moins cher.

## Réflexe GCP
Même logique : **Persistent Disk** (block, pour VM/BDD), **Cloud Storage** (object, fichiers/backups), **Filestore** (file, partage entre VM).

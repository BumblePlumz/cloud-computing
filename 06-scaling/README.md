# Mini-Projet 06 — Scalabilité (Auto Scaling)

Ajuster **automatiquement** le nombre d'instances selon la charge : ajouter des
serveurs quand le CPU monte, en retirer quand il baisse.

## ⚠️ Limite LocalStack (important)
**Auto Scaling n'est PAS supporté par LocalStack Community** (c'est une fonctionnalité
**Pro**). Ce projet ne se déploie donc **pas** en local comme les 5 premiers.
Le code est correct et **validé** (`make validate`) ; il faut **LocalStack Pro** ou un
**vrai compte AWS** pour `apply`. Pour cette raison, il n'est **pas** inclus dans le
`make up` racine.

## Théorie
| Concept | Définition |
|---------|-----------|
| Scaling **vertical** | grossir une instance (plus de CPU/RAM) |
| Scaling **horizontal** | ajouter des instances identiques (scale out) |
| **Auto Scaling Group** | groupe qui ajuste le nombre d'instances tout seul |
| **Launch Template** | la config de chaque instance créée |
| Politique de scaling | quand ajouter/retirer (seuils CPU) |
| **Cooldown** | délai entre deux actions (évite l'oscillation) |

## Fichiers
| Fichier | Rôle |
|---------|------|
| `main.tf` | Provider |
| `network.tf` | VPC + subnet + security group |
| `scaling.tf` | Launch Template, ASG (min1/max5), policies scale out/in, alarmes CloudWatch |
| `outputs.tf` | Nom + capacité de l'ASG |

## Le mécanisme
```
Trafic → Load Balancer → Instances (1 à 5)
   CPU > 70% (2 min) → Alarme CloudWatch → Scale OUT (+2)
   CPU < 20% (5 min) → Alarme CloudWatch → Scale IN  (-1)
   Instance en panne → Health Check → remplacée automatiquement
```

## Lancer
```bash
make validate    # vérifie la syntaxe (fonctionne en Community)
# Sur LocalStack Pro ou AWS réel :
make up          # déploie ASG + alarmes
make verify      # affiche l'ASG et ses politiques
make simulate    # pousse une métrique CPU + force desired=3
```

## Réflexe GCP
Équivalent : **Managed Instance Group (MIG)** + **Instance Template** + **Autoscaler**
(basé sur l'utilisation CPU ou des métriques custom). Même logique scale out / scale in.

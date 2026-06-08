# Mini-Projet 02 — FaaS (Lambda + API Gateway)

API **serverless** : une fonction Lambda exposée par une API Gateway HTTP, branchée sur DynamoDB.
Aucun serveur à gérer, facturation à l'invocation, scaling automatique.

```
[Front / curl]  →  API Gateway (URL HTTP)  →  Lambda faas-api  →  DynamoDB faas-users
```

## Fichiers
| Fichier | Rôle |
|---------|------|
| `main.tf` | Provider AWS (LocalStack en dev / AWS réel en prod) |
| `handler.py` | Code de la Lambda (intégration proxy API Gateway) |
| `dynamodb.tf` | Table `faas-users` |
| `lambda.tf` | Zip + rôle IAM (moindre privilège) + fonction Lambda |
| `apigateway.tf` | API REST, ressource `{proxy+}`, intégration `AWS_PROXY`, stage `dev` |
| `outputs.tf` | Affiche l'`invoke_url` à appeler |
| `front/index.html` | Petit front de démo (HTML/JS, sans serveur) |

## Routes exposées
| Méthode | Chemin | Effet |
|---------|--------|-------|
| GET | `/hello?nom=X` | Réponse simple, sans AWS (valide la chaîne API GW → Lambda) |
| GET | `/users` | Liste les utilisateurs (scan DynamoDB) |
| POST | `/users` | Crée un utilisateur (body JSON `{nom, email}`) |

## Lancer le projet
```bash
make localstack-start      # LocalStack avec lambda + apigateway
make terraform-init
make terraform-apply       # crée Lambda + API Gateway + DynamoDB
make api-url               # affiche l'URL de base de l'API
make api-test              # teste /hello, POST /users, GET /users
```
Nettoyage : `make terraform-destroy`.

> ⚠️ La **1ʳᵉ invocation** de la Lambda est lente (*cold start*) : LocalStack télécharge l'image runtime `python:3.11`.

## Tester le front
1. `make api-url` → copier l'URL.
2. Servir le dossier : `cd front && python -m http.server 8000` (le navigateur bloque `file://`).
3. Ouvrir http://localhost:8000 , coller l'URL dans le champ, cliquer **GET /users** / **POST /users**.

L'URL (`api_id`) change à chaque `destroy`/`apply` — il faut la recoller dans le front.

## Notions clés
- **FaaS** : on déploie une fonction, pas un serveur ; exécutée à la demande.
- **Intégration proxy (`AWS_PROXY`)** : API Gateway transmet toute la requête (méthode, chemin, body) à la Lambda, qui renvoie `{statusCode, headers, body}`.
- **CORS** : la Lambda renvoie les en-têtes `Access-Control-*` + gère le préflight `OPTIONS` → un front navigateur peut l'appeler.
- **Moindre privilège** : le rôle de la Lambda n'autorise que les logs + les actions DynamoDB sur sa table.

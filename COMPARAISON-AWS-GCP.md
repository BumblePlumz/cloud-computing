# AWS (racine) vs GCP (dossier `gcp/`) — comparaison

Les deux projets font **exactement la même chose** : créer un BaaS minimal
(DB + stockage + identité + logs). Ils diffèrent uniquement par le cloud cible.

## Structure

```
.
├── main.tf          ← provider AWS            │   gcp/main.tf          ← provider google
├── dynamodb.tf      ← 2 tables users/sessions │   gcp/firestore.tf     ← 1 base + TTL
├── s3.tf            ← bucket + versioning     │   gcp/storage.tf       ← bucket + versioning
├── iam.tf           ← user + policy JSON      │   gcp/iam.tf           ← SA + role bindings
├── cloudwatch.tf    ← log group               │   gcp/logging.tf       ← log bucket
├── outputs.tf       ← 5 outputs               │   gcp/outputs.tf       ← 5 outputs
├── app.py           ← boto3                   │   gcp/app.py           ← google-cloud-*
└── Makefile         ← targets LocalStack+AWS  │   (pas de Makefile, voir gcp/README.md)
```

## Le même acte métier, deux syntaxes

### Créer une base et définir un TTL

**AWS — DynamoDB** ([dynamodb.tf](dynamodb.tf))
```hcl
resource "aws_dynamodb_table" "sessions" {
  name         = "baas-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}
```

**GCP — Firestore** ([gcp/firestore.tf](gcp/firestore.tf))
```hcl
resource "google_firestore_database" "baas" {
  name        = "(default)"
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"
}

resource "google_firestore_field" "sessions_ttl" {
  database   = google_firestore_database.baas.name
  collection = "sessions"
  field      = "expiresAt"
  ttl_config {}
}
```

**Ce qui change** : DynamoDB exige de déclarer la table **et** son schéma de clés. Firestore déclare juste la base, les collections se créent à la volée — donc pas de `aws_dynamodb_table.users` côté GCP, c'est la ligne `db.collection("users").document(...).set(...)` dans [app.py](gcp/app.py) qui les matérialise.

---

### Créer un bucket avec versioning

**AWS — S3** ([s3.tf](s3.tf))
```hcl
resource "aws_s3_bucket" "user_files" {
  bucket = "baas-user-files"
}

resource "aws_s3_bucket_versioning" "user_files" {
  bucket = aws_s3_bucket.user_files.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

**GCP — Cloud Storage** ([gcp/storage.tf](gcp/storage.tf))
```hcl
resource "google_storage_bucket" "user_files" {
  name          = "${var.gcp_project}-baas-user-files"
  location      = var.gcp_region
  force_destroy = true

  versioning {
    enabled = true
  }
}
```

**Ce qui change** : AWS sépare le bucket et la config versioning en deux ressources ; GCP les met dans un seul bloc. Sinon idem.

---

### Identité machine + permissions

**AWS — IAM** ([iam.tf](iam.tf))
```hcl
resource "aws_iam_user" "baas_client" {
  name = "baas-client"
}

data "aws_iam_policy_document" "baas_client" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", ...]
    resources = [aws_dynamodb_table.users.arn]
  }
}

resource "aws_iam_user_policy" "baas_client" {
  user   = aws_iam_user.baas_client.name
  policy = data.aws_iam_policy_document.baas_client.json
}
```

**GCP — Service Account + IAM bindings** ([gcp/iam.tf](gcp/iam.tf))
```hcl
resource "google_service_account" "baas_client" {
  account_id = "baas-client"
}

resource "google_project_iam_member" "baas_client_firestore" {
  role   = "roles/datastore.user"
  member = "serviceAccount:${google_service_account.baas_client.email}"
}

resource "google_storage_bucket_iam_member" "baas_client_storage" {
  bucket = google_storage_bucket.user_files.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.baas_client.email}"
}
```

**Ce qui change** — c'est la **différence philosophique** entre AWS et GCP :

- **AWS** : tu écris toi-même une policy JSON listant chaque action (`dynamodb:GetItem`, `s3:PutObject`, etc.). Ultra granulaire mais verbeux.
- **GCP** : tu choisis un **rôle prédéfini** par Google (`roles/datastore.user`, `roles/storage.objectAdmin`). Plus simple mais moins granulaire.

Les deux marchent, mais la culture sécu est différente.

---

## Le code applicatif

### AWS ([app.py](app.py))
```python
import boto3
dynamo = boto3.resource("dynamodb", endpoint_url=..., aws_access_key_id="...", ...)
s3     = boto3.client("s3", ...)

dynamo.Table("baas-users").put_item(Item=user)
s3.put_object(Bucket="baas-user-files", Key=cle, Body=contenu.encode())
```

### GCP ([gcp/app.py](gcp/app.py))
```python
from google.cloud import firestore, storage
db  = firestore.Client(project=GCP_PROJECT)   # lit GOOGLE_APPLICATION_CREDENTIALS auto
gcs = storage.Client(project=GCP_PROJECT)

db.collection("users").document(user["userId"]).set(user)
gcs.bucket(FILES_BUCKET).blob(cle).upload_from_string(contenu)
```

**Ce qui change** :
- **Auth** : boto3 prend des clés dans le code (ou var d'env `AWS_*`), GCP lit le chemin d'un JSON dans `GOOGLE_APPLICATION_CREDENTIALS`
- **API style** : boto3 est très proche de l'API REST brute (`put_item`, `put_object`), GCP SDK est plus "orienté objet" (`collection().document().set()`)
- Le **concept** est identique : SDK client → service managé.

---

## Le test décisif de la portabilité

Si tu changes de boulot et qu'on te dit "on est sur GCP" au lieu d'AWS, qu'est-ce qui change pour toi ?

| Skill | AWS | GCP | Transférable ? |
|---|---|---|---|
| Terraform (HCL, workflow, state) | ✅ | ✅ | 💯 |
| Comprendre NoSQL / Object storage / IAM / Logs | ✅ | ✅ | 💯 |
| Lire une doc de provider Terraform | ✅ | ✅ | 💯 |
| Syntaxe exacte des ressources (`aws_*` vs `google_*`) | ✅ | ❌ | Faut juste lire la doc |
| Savoir écrire une IAM policy JSON | ✅ | ❌ | Moins utile côté GCP |
| Le nom des services | ✅ | ❌ | Traduction à faire |

**Verdict** : 80-90% de ce que tu apprends est transférable. Les 10-20% restants c'est de la traduction de noms.

---

## Pour aller plus loin

- [Azure avec Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) — même principe, ressources `azurerm_*`
- [OVHcloud](https://registry.terraform.io/providers/ovh/ovh/latest/docs) — provider OVH aussi sur Terraform
- [Kubernetes avec Terraform](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) — tu peux déclarer tes déploiements K8s comme tu le fais pour AWS

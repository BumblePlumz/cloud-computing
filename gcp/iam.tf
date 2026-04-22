# Equivalent IAM côté GCP
#
# Différences conceptuelles clés :
# - AWS : on crée un "IAM user" (entité humain-like avec access key/secret)
# - GCP : on crée un "service account" (entité machine avec email + clé JSON)
# - AWS : on attache une policy JSON au user
# - GCP : on fait des "IAM bindings" qui associent un rôle (role) à un membre
#
# Autre différence : GCP a des rôles prédéfinis très granulaires
# (roles/datastore.user, roles/storage.objectAdmin, etc.) alors qu'AWS
# demande souvent d'écrire une policy custom.

resource "google_service_account" "baas_client" {
  account_id   = "baas-client"
  display_name = "BaaS client service account"
  description  = "Compte de service pour le client BaaS (équivalent AWS IAM user baas-client)"
}

# Permission d'accès Firestore (équivalent des actions dynamodb:* sur AWS)
resource "google_project_iam_member" "baas_client_firestore" {
  project = var.gcp_project
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.baas_client.email}"
}

# Permission d'accès Cloud Storage (scopée au bucket, équivalent des actions s3:* sur AWS)
resource "google_storage_bucket_iam_member" "baas_client_storage" {
  bucket = google_storage_bucket.user_files.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.baas_client.email}"
}

# Permission d'écrire des logs Cloud Logging (équivalent logs:PutLogEvents sur AWS)
resource "google_project_iam_member" "baas_client_logging" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.baas_client.email}"
}

# Clé JSON pour le service account (l'équivalent "access key + secret" côté AWS)
# Attention : cette clé JSON est sensible, pareil qu'une access key AWS.
resource "google_service_account_key" "baas_client" {
  service_account_id = google_service_account.baas_client.name
}

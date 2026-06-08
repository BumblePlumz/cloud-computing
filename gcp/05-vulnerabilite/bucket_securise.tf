# Version corrigée côté GCP : les failles sont fermées.

resource "google_storage_bucket" "securise" {
  name          = "${var.gcp_project}-bucket-securise-demo"
  location      = var.gcp_region
  force_destroy = true

  # CORRECTION 1 : empêche TOUT accès public, même ajouté par erreur
  # (équiv. Public Access Block AWS — c'est le filet de sécurité maître)
  public_access_prevention = "enforced"

  # CORRECTION 2 : désactive les ACL, tout passe par IAM (équiv. BucketOwnerEnforced)
  uniform_bucket_level_access = true

  # CORRECTION 3 : versioning (récupération après suppression/corruption)
  versioning {
    enabled = true
  }

  labels = {
    owner          = "equipe-a"
    classification = "confidentiel"
  }

  # Chiffrement : par défaut, GCS chiffre tout avec des clés gérées par Google.
  # Pour des clés gérées par le client (CMEK), on ajouterait :
  #   encryption { default_kms_key_name = google_kms_crypto_key.x.id }
}

# Aucune liaison "allUsers" : le bucket reste PRIVÉ (accès via IAM uniquement).

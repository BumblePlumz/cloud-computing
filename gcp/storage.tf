# Equivalent S3 côté GCP : Cloud Storage (GCS)
#
# Différences avec aws_s3_bucket :
# - Le nom du bucket doit être globalement unique (comme AWS). Ici on préfixe
#   avec le project_id pour être sûr de ne pas collisionner.
# - `force_destroy = true` permet de supprimer le bucket même s'il contient
#   des fichiers (équivalent du comportement par défaut AWS qui échoue).
# - Versioning : identique dans l'esprit, syntaxe légèrement différente.

resource "google_storage_bucket" "user_files" {
  name          = "${var.gcp_project}-baas-user-files"
  location      = var.gcp_region
  force_destroy = true

  versioning {
    enabled = true
  }

  labels = {
    service    = "baas"
    managed-by = "terraform"
  }
}

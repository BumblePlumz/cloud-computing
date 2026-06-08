# Equivalent DynamoDB côté GCP : Firestore
#
# Différence majeure avec DynamoDB :
# - DynamoDB : on déclare les tables ET leur schéma de clés dans Terraform
# - Firestore : on déclare UNIQUEMENT la base. Les collections ("users", "sessions")
#   se créent à la volée quand le code client écrit le premier document.
#   Firestore est 100% schemaless.

resource "google_firestore_database" "baas" {
  project     = var.gcp_project
  name        = "(default)"
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"
}

# Equivalent du TTL sur DynamoDB sessions : on configure un champ TTL
# sur la collection "sessions" (le document est supprimé auto quand
# l'attribut "expiresAt" est dans le passé).
resource "google_firestore_field" "sessions_ttl" {
  project    = var.gcp_project
  database   = google_firestore_database.baas.name
  collection = "sessions"
  field      = "expiresAt"

  ttl_config {}

  depends_on = [google_firestore_database.baas]
}

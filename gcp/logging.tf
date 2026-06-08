# Equivalent CloudWatch Logs côté GCP : Cloud Logging
#
# Différence majeure avec AWS :
# - AWS : tu crées un "log group" puis tu envoies des "log events" dedans
# - GCP : les logs arrivent automatiquement dans le projet, tu peux seulement
#   créer des "log buckets" pour les router/filtrer et choisir la rétention
#
# Ici on crée un log bucket custom équivalent au log group AWS /baas/app.

resource "google_logging_project_bucket_config" "baas_app" {
  project        = var.gcp_project
  location       = "global"
  retention_days = 7
  bucket_id      = "baas-app"
}

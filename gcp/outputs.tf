output "firestore_database" {
  description = "Base Firestore (équivalent des tables DynamoDB AWS)"
  value       = google_firestore_database.baas.name
}

output "files_bucket" {
  description = "Bucket Cloud Storage (équivalent S3 AWS baas-user-files)"
  value       = google_storage_bucket.user_files.name
}

output "baas_client_service_account" {
  description = "Service account client (équivalent IAM user AWS baas-client)"
  value       = google_service_account.baas_client.email
}

output "log_bucket" {
  description = "Log bucket Cloud Logging (équivalent log group AWS /baas/app)"
  value       = google_logging_project_bucket_config.baas_app.id
}

# La clé JSON du service account — équivalent access_key+secret côté AWS.
# On l'expose en `sensitive` (Terraform ne l'affichera pas dans les logs).
output "baas_client_credentials_json" {
  description = "Clé JSON à utiliser dans GOOGLE_APPLICATION_CREDENTIALS côté client"
  value       = google_service_account_key.baas_client.private_key
  sensitive   = true
}

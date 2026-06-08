output "vulnerable_bucket" {
  description = "Bucket GCS non sécurisé (démo)"
  value       = google_storage_bucket.vulnerable.name
}

output "secure_bucket" {
  description = "Bucket GCS sécurisé (corrigé)"
  value       = google_storage_bucket.securise.name
}

output "vulnerable_bucket" {
  description = "Bucket non sécurisé (démo)"
  value       = aws_s3_bucket.vulnerable.id
}

output "secure_bucket" {
  description = "Bucket sécurisé (corrigé)"
  value       = aws_s3_bucket.securise.id
}

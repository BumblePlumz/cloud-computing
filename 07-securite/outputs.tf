output "kms_key_arn" {
  description = "Clé KMS centrale"
  value       = aws_kms_key.main.arn
}

output "app_bucket" {
  description = "Bucket applicatif chiffré"
  value       = aws_s3_bucket.app_files.id
}

output "backup_bucket" {
  description = "Bucket de backup"
  value       = aws_s3_bucket.backup.id
}

output "app_role" {
  description = "Rôle IAM du backend"
  value       = aws_iam_role.app.name
}

output "alerts_topic" {
  description = "Topic SNS d'alertes"
  value       = aws_sns_topic.alerts.arn
}

output "log_groups" {
  value = [aws_cloudwatch_log_group.app.name, aws_cloudwatch_log_group.security.name]
}

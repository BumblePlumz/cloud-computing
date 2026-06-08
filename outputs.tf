output "users_table" {
  description = "Nom de la table DynamoDB utilisateurs"
  value       = aws_dynamodb_table.users.name
}

output "sessions_table" {
  description = "Nom de la table DynamoDB sessions"
  value       = aws_dynamodb_table.sessions.name
}

output "files_bucket" {
  description = "Nom du bucket S3 fichiers utilisateurs"
  value       = aws_s3_bucket.user_files.id
}

output "baas_client_user" {
  description = "Utilisateur IAM dédié au client BaaS"
  value       = aws_iam_user.baas_client.name
}

output "log_group" {
  description = "CloudWatch log group pour le monitoring BaaS"
  value       = aws_cloudwatch_log_group.baas_app.name
}

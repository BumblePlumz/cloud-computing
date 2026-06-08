output "collegue_user" {
  description = "Nom de l'utilisateur IAM du collègue"
  value       = aws_iam_user.collegue.name
}

output "group" {
  description = "Groupe IAM"
  value       = aws_iam_group.developers.name
}

output "policy_arn" {
  description = "ARN de la policy EC2 limitée"
  value       = aws_iam_policy.dev_ec2.arn
}

output "collegue_access_key" {
  description = "Access key ID à transmettre au collègue"
  value       = aws_iam_access_key.collegue.id
}

output "collegue_secret_key" {
  description = "Secret key (masquée : terraform output -raw collegue_secret_key)"
  value       = aws_iam_access_key.collegue.secret
  sensitive   = true
}

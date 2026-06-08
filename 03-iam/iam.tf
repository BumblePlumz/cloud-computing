# ── Accès sécurisés pour un collègue (moindre privilège) ──────────
# Le collègue peut déployer des EC2, mais PAS toucher à IAM / S3 / KMS.

# 1. Groupe "developers" (réutilisable pour plusieurs collègues)
resource "aws_iam_group" "developers" {
  name = "developers"
}

# 2. Policy : EC2 limité + Deny explicite sur les ressources critiques
resource "aws_iam_policy" "dev_ec2" {
  name        = "DevEC2LimitedPolicy"
  description = "Collègue : peut déployer EC2 mais pas modifier IAM/S3/KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Deploy"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowReadOwnLogs"
        Effect   = "Allow"
        Action   = ["logs:GetLogEvents", "logs:DescribeLogGroups"]
        Resource = "arn:aws:logs:*:*:log-group:/collegue/*"
      },
      {
        Sid      = "DenyIAMAndS3"
        Effect   = "Deny"
        Action   = ["iam:*", "s3:*", "kms:*"] # JAMAIS d'accès IAM/S3/KMS
        Resource = "*"
      },
    ]
  })
}

# 3. Attacher la policy au GROUPE (jamais directement à l'utilisateur)
resource "aws_iam_group_policy_attachment" "dev" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.dev_ec2.arn
}

# 4. Compte du collègue
resource "aws_iam_user" "collegue" {
  name = "collegue-dupont"
  tags = {
    Role   = "developer"
    Projet = "cours-terraform"
  }
}

# 5. Ajouter le collègue au groupe
resource "aws_iam_user_group_membership" "collegue" {
  user   = aws_iam_user.collegue.name
  groups = [aws_iam_group.developers.name]
}

# 6. Clés d'accès programmatiques (à transmettre de façon sécurisée)
resource "aws_iam_access_key" "collegue" {
  user = aws_iam_user.collegue.name
}

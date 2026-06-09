# ── PILIER 1 — IAM : rôles, moindre privilège, et clé KMS centrale ──

# Clé KMS : chiffrement centralisé, partagée par tous les piliers
resource "aws_kms_key" "main" {
  description         = "Cle principale securite application"
  enable_key_rotation = true
  tags                = { ManagedBy = "terraform" }
}

resource "aws_kms_alias" "main" {
  name          = "alias/app-securisee"
  target_key_id = aws_kms_key.main.key_id
}

# Rôle de l'application backend (accès DynamoDB + S3, déchiffrement KMS)
resource "aws_iam_role" "app" {
  name = "app-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "app" {
  name = "app-backend-policy"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DynamoDB"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        Resource = "arn:aws:dynamodb:*:*:table/baas-*"
      },
      {
        Sid      = "S3"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["arn:aws:s3:::app-files-*", "arn:aws:s3:::app-files-*/*"]
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:PutLogEvents", "logs:CreateLogStream"]
        Resource = "arn:aws:logs:*:*:log-group:/app/*"
      },
      {
        Sid      = "KMS"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.main.arn
      },
      {
        Sid      = "DenyAdmin"
        Effect   = "Deny"
        Action   = ["iam:*", "s3:DeleteBucket", "dynamodb:DeleteTable", "kms:DeleteKey"]
        Resource = "*"
      },
    ]
  })
}

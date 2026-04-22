# Utilisateur IAM dédié au client BaaS (apps mobiles / front)
resource "aws_iam_user" "baas_client" {
  name = "baas-client"

  tags = {
    Service   = "BaaS"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "baas_client" {
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      aws_dynamodb_table.users.arn,
      aws_dynamodb_table.sessions.arn,
    ]
  }

  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.user_files.arn}/*"]
  }

  statement {
    sid       = "S3Bucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.user_files.arn]
  }
}

resource "aws_iam_user_policy" "baas_client" {
  name   = "baas-client-policy"
  user   = aws_iam_user.baas_client.name
  policy = data.aws_iam_policy_document.baas_client.json
}

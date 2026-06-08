# 1. Zip de la fonction (genere automatiquement par Terraform)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/lambda.zip"
}

# 2. Role d'execution de la Lambda
resource "aws_iam_role" "lambda" {
  name = "faas-api-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 3. Permissions : logs + acces a la table DynamoDB (moindre privilege)
resource "aws_iam_role_policy" "lambda" {
  name = "faas-api-policy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan", "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = aws_dynamodb_table.users.arn
      }
    ]
  })
}

# 4. La fonction Lambda (handler.handler)
resource "aws_lambda_function" "api" {
  function_name    = "faas-api"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  handler          = "handler.handler"
  role             = aws_iam_role.lambda.arn
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      USERS_TABLE      = aws_dynamodb_table.users.name
      AWS_ENDPOINT_URL = var.use_localstack ? "http://host.docker.internal:4566" : ""
    }
  }
}

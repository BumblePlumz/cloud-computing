# Table utilisateurs servie par l'API serverless
resource "aws_dynamodb_table" "users" {
  name         = "faas-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Service   = "FaaS"
    ManagedBy = "terraform"
  }
}

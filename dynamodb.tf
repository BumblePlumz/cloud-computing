# Table utilisateurs (equivalent Firebase Firestore)
resource "aws_dynamodb_table" "users" {
  name         = "baas-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Service   = "BaaS"
    ManagedBy = "terraform"
  }
}

# Table sessions (stockage authentification)
resource "aws_dynamodb_table" "sessions" {
  name         = "baas-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Service   = "BaaS"
    ManagedBy = "terraform"
  }
}

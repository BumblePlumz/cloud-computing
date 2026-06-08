# !! CE CODE EST VOLONTAIREMENT NON SECURISE — USAGE PEDAGOGIQUE UNIQUEMENT !!
# Ne JAMAIS reproduire sur un vrai compte AWS.

resource "aws_s3_bucket" "vulnerable" {
  bucket = "bucket-vulnerable-demo"
  # OUBLI 1 : pas de tags, pas de classification
}

# Active les ACL (necessaire pour poser une ACL publique)
resource "aws_s3_bucket_ownership_controls" "vulnerable" {
  bucket = aws_s3_bucket.vulnerable.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

# OUBLI 2 : acces public NON bloque (tout est ouvert)
resource "aws_s3_bucket_public_access_block" "vulnerable" {
  bucket                  = aws_s3_bucket.vulnerable.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# OUBLI 3 : ACL publique — tout internet peut lire
resource "aws_s3_bucket_acl" "vulnerable" {
  depends_on = [
    aws_s3_bucket_ownership_controls.vulnerable,
    aws_s3_bucket_public_access_block.vulnerable,
  ]
  bucket = aws_s3_bucket.vulnerable.id
  acl    = "public-read"
}

# OUBLI 4 : pas de chiffrement  (aucune ressource encryption)
# OUBLI 5 : pas de versioning   (aucune ressource versioning)
# OUBLI 6 : politique permissive — Principal "*" autorise tout le monde
resource "aws_s3_bucket_policy" "vulnerable" {
  bucket = aws_s3_bucket.vulnerable.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadEverything"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.vulnerable.arn,
        "${aws_s3_bucket.vulnerable.arn}/*",
      ]
    }]
  })
}

# ── PILIER 5 — Backup automatique et PRA ──────────────────────────

# Bucket de backup : chiffré KMS + versioning + lifecycle (IA -> Glacier -> suppression)
resource "aws_s3_bucket" "backup" {
  bucket = "app-backups-securises"
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  count  = var.enable_s3_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.backup.id
  rule {
    id     = "backup-lifecycle"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration { days = 365 }
  }
}

# AWS Backup (vault + plan) : Pro / AWS réel uniquement (var.enable_aws_backup)
resource "aws_backup_vault" "main" {
  count       = var.enable_aws_backup ? 1 : 0
  name        = "app-backup-vault"
  kms_key_arn = aws_kms_key.main.arn
}

resource "aws_backup_plan" "daily" {
  count = var.enable_aws_backup ? 1 : 0
  name  = "DailyBackupPlan"
  rule {
    rule_name         = "backup-quotidien"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 2 * * ? *)" # 2h chaque nuit
    lifecycle { delete_after = 30 }
  }
}

# ── Deux types de stockage à comparer ────────────────────────────

# Object Storage : un bucket S3 (fichiers entiers, accès HTTP REST)
resource "aws_s3_bucket" "benchmark_object" {
  bucket = "benchmark-object-storage"

  tags = {
    Service   = "Stockage"
    Type      = "object"
    ManagedBy = "terraform"
  }
}

# Block Storage : un volume EBS (disque attaché à une VM, accès byte par byte)
# Note : sur LocalStack c'est un mock — non réellement benchmarkable (voir README).
resource "aws_ebs_volume" "benchmark_block" {
  availability_zone = "${var.aws_region}a"
  size              = 10   # Go (pour le test)
  type              = "gp3"

  tags = {
    Name      = "benchmark-block-storage"
    Service   = "Stockage"
    Type      = "block"
    ManagedBy = "terraform"
  }
}

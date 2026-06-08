# !! VOLONTAIREMENT NON SECURISE — PEDAGOGIQUE. Ne JAMAIS faire en vrai. !!
#
# Equivalent GCP du bucket S3 troué (mini-projet 05).
# Correspondances AWS -> GCP :
#   aws_s3_bucket_public_access_block  -> public_access_prevention
#   ACL public-read / policy Principal:*  -> IAM member "allUsers"
#   BucketOwnerEnforced (ACL off)      -> uniform_bucket_level_access

resource "google_storage_bucket" "vulnerable" {
  name          = "${var.gcp_project}-bucket-vulnerable-demo"
  location      = var.gcp_region
  force_destroy = true

  # FAILLE 1 : le garde-fou maître n'est PAS appliqué (équiv. Public Access Block off)
  public_access_prevention = "inherited"

  # FAILLE 2 : ACL fine-grained activées (équiv. ACL AWS activées)
  uniform_bucket_level_access = false

  # FAILLE 3 : pas de versioning (suppression irréversible)
  # (bloc versioning absent)
}

# FAILLE 4 : bucket rendu PUBLIC à tout internet.
# "allUsers" = n'importe quel anonyme (équiv. Principal:"*" / ACL public-read côté AWS).
resource "google_storage_bucket_iam_member" "vulnerable_public" {
  bucket = google_storage_bucket.vulnerable.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

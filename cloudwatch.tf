# Log group pour l'observabilite du BaaS (equivalent Firebase Analytics / logs applicatifs)
resource "aws_cloudwatch_log_group" "baas_app" {
  name              = "/baas/app"
  retention_in_days = 7

  tags = {
    Service   = "BaaS"
    ManagedBy = "terraform"
  }
}

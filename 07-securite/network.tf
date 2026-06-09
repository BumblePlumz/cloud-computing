# ── PILIER 3 — Sécurité réseau (isolation) ────────────────────────

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "app-vpc" }
}

# Subnet privé (base de données, pas d'accès internet direct)
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags       = { Name = "private-db", Tier = "database" }
}

# Security Group : HTTPS entrant uniquement, sortie interne au VPC
resource "aws_security_group" "app" {
  name   = "app-securisee-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS uniquement"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Interne au VPC seulement"
  }
}

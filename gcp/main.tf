terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Equivalent GCP de var.aws_region côté AWS
variable "gcp_project" {
  description = "ID du projet GCP (ex: mon-baas-123456)"
  type        = string
}

variable "gcp_region" {
  description = "Région GCP (équivalent us-east-1 côté AWS)"
  type        = string
  default     = "us-central1"
}

variable "gcp_credentials_file" {
  description = "Chemin vers le JSON du service account (optionnel si `gcloud auth application-default login` est fait)"
  type        = string
  default     = null
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials_file != null ? file(var.gcp_credentials_file) : null
}

terraform {
  required_version = ">= 1.5.7"

  backend "gcs" {
    bucket = "secureinventory-tfstate-zoeldjian9"
    prefix = "gcp-lab"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.5.0"
    }
  }
}
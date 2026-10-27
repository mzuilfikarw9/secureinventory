locals {
  labels = {
    app        = "secureinventory"
    env        = "lab"
    managed-by = "terraform"
  }
}

# Credentials come from `gcloud auth application-default login`; no key files.
provider "google" {
  project        = var.project_id
  region         = var.region
  default_labels = local.labels
}

resource "google_project_service" "apis" {
  for_each = toset(["compute.googleapis.com", "container.googleapis.com"])

  service            = each.value
  disable_on_destroy = false
}

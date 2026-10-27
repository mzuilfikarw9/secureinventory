# Dedicated node identity instead of the default Compute Engine service
# account, which has the broad Editor role.
resource "google_service_account" "nodes" {
  account_id   = "${var.name_prefix}-nodes"
  display_name = "SecureInventory lab GKE nodes"
}

resource "google_project_iam_member" "nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

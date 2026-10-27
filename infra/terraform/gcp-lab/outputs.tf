output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.lab.name
}

output "location" {
  description = "GKE cluster zone."
  value       = google_container_cluster.lab.location
}

output "get_credentials_command" {
  description = "Command to configure kubectl for this cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.lab.name} --zone ${var.zone} --project ${var.project_id}"
}

output "node_service_account" {
  description = "Email of the node service account."
  value       = google_service_account.nodes.email
}

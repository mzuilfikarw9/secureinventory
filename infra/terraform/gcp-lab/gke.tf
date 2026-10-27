resource "google_container_cluster" "lab" {
  name     = "${var.name_prefix}-gke"
  location = var.zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.nodes.id

  # Nodes are managed by the separate node pool below.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Lab cluster: allow `terraform destroy`.
  deletion_protection = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Nodes get private IPs only; the API endpoint stays public but is limited
  # to authorized_cidr.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.authorized_cidr
      display_name = "admin"
    }
  }

  # Dataplane V2 (eBPF/Cilium) enforces Kubernetes NetworkPolicy natively.
  datapath_provider = "ADVANCED_DATAPATH"

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  resource_labels = local.labels
}

resource "google_container_node_pool" "spot" {
  name       = "${var.name_prefix}-spot"
  cluster    = google_container_cluster.lab.id
  location   = var.zone
  node_count = var.node_count

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    image_type      = "COS_CONTAINERD"
    spot            = true
    disk_type       = "pd-balanced"
    disk_size_gb    = var.disk_size_gb
    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    resource_labels = local.labels

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  depends_on = [google_project_iam_member.nodes]
}

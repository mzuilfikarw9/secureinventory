variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "GCP region for the subnet, router and NAT, e.g. us-central1."
  type        = string
}

variable "zone" {
  description = "GCP zone for the cluster and node, inside var.region, e.g. us-central1-a."
  type        = string
}

variable "authorized_cidr" {
  description = "CIDR allowed to reach the cluster API, e.g. your public IP as x.x.x.x/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.authorized_cidr, 0)) && var.authorized_cidr != "0.0.0.0/0"
    error_message = "authorized_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "secinv-lab"

  validation {
    # Keeps "<prefix>-nodes" within the 30-character service account ID limit.
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}$", var.name_prefix))
    error_message = "name_prefix must be 2-23 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "machine_type" {
  description = "Machine type for the Spot node."
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Boot disk size per node in GB."
  type        = number
  default     = 30
}

variable "node_count" {
  description = "Number of nodes. Set to 0 to pause compute costs between sessions."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 0 && var.node_count <= 3
    error_message = "node_count must be between 0 and 3."
  }
}

variable "subnet_cidr" {
  description = "Primary range for node IPs."
  type        = string
  default     = "10.10.0.0/24"
}

variable "pods_cidr" {
  description = "Secondary range for pod IPs."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range for service IPs."
  type        = string
  default     = "10.30.0.0/20"
}

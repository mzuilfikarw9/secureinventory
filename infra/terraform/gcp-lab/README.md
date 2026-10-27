# GKE lab cluster (Phase 1)

Minimal, disposable GKE environment for the SecureInventory DevSecOps lab:

- Custom VPC with one subnet (secondary ranges for pods and services)
- Cloud Router and Cloud NAT for outbound access from private nodes
- Dedicated least-privilege node service account
- One zonal GKE Standard cluster with private nodes; the API endpoint is
  public but restricted to `authorized_cidr`
- One Spot `e2-standard-2` node (30 GB `pd-balanced` boot disk)

State is local (`terraform.tfstate`, git-ignored). It contains sensitive
cluster data: never commit or share it. If it is lost, resources must be
deleted manually.

## Prerequisites

- Terraform >= 1.5.7, `gcloud`, `kubectl` and `gke-gcloud-auth-plugin`
- A GCP project with billing enabled
- Credentials via `gcloud auth application-default login` (no key files)

## Validate

```bash
cd infra/terraform/gcp-lab
terraform fmt -check -diff
terraform init
terraform validate
trivy config .
```

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values; file is git-ignored
terraform plan -out=tfplan
terraform apply tfplan
```

Then run the `get_credentials_command` output to configure `kubectl`.

If your public IP changes, update `authorized_cidr` and apply again.

## Cost

Rough estimate for us-central1, 730 hours/month. Verify current prices for
your region with the GCP pricing calculator.

| Item | Approx. per month |
|---|---|
| GKE management fee ($0.10/hour), covered by the free-tier credit for one zonal cluster per billing account | $0 |
| 1× `e2-standard-2` Spot node | ~$15 |
| 30 GB `pd-balanced` boot disk | ~$3 |
| Cloud NAT (1 gateway, little traffic) | ~$1–2 |
| **Total running 24/7** | **~$20** |

To pause compute between sessions, set `node_count = 0` and apply.

## Teardown

1. Delete anything Kubernetes created outside Terraform, or it may be left
   behind and keep billing (load balancers, persistent disks):

   ```bash
   kubectl delete ingress,service,pvc --all -n <namespace>   # each namespace you used
   ```

2. Destroy and review the plan before confirming:

   ```bash
   terraform destroy
   ```

3. Check that nothing remains (all lists should be empty):

   ```bash
   gcloud container clusters list
   gcloud compute instances list
   gcloud compute disks list
   gcloud compute forwarding-rules list
   gcloud compute addresses list
   ```

4. Remove the cluster's context from your kubeconfig:
   `kubectl config delete-context <context>`.

The enabled `compute` and `container` APIs stay enabled (no charge).

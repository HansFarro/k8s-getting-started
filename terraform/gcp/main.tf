# VARIABLES
variable "credential_path" {}
variable "project_id" {}
variable "zones" {}
variable "region" {}
variable "cluster_name" {}
variable "network" {
  default = "vpc-gke"
}
variable "subnet" {
  default = "sub-gke"
}
variable "ip_range_pods_name" {
  default = "ip-range-pods"
}
variable "ip_range_services_name" {
  default = "ip-range-services"
}

# PROVIDERS
provider "google" {
  credentials = file(var.credential_path)
  project     = var.project_id
  region      = var.region
}

# MODULES
module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = var.cluster_name
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.0"
  project_id   = var.project_id
  network_name = var.network
  subnets = [
    {
      subnet_name   = var.subnet
      subnet_ip     = "10.10.0.0/16"
      subnet_region = var.region
    },
  ]
  secondary_ranges = {
    (var.subnet) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "10.30.0.0/16"
      },
    ]
  }
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source            = "terraform-google-modules/kubernetes-engine/google"
  project_id        = var.project_id
  name              = var.cluster_name
  regional          = true
  region            = var.region
  zones             = var.zones
  network           = module.vpc.network_name
  subnetwork        = module.vpc.subnets_names[0]
  ip_range_pods     = var.ip_range_pods_name
  ip_range_services = var.ip_range_services_name

  node_pools = [
    {
      name         = "node-pool"
      machine_type = "e2-medium"
      min_count    = 1
      max_count    = 1
    },
  ]
}

# OUTPUT
output "id" {
  description = "Cluster ID"
  value       = module.gke.cluster_id
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

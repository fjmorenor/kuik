# ─────────────────────────────────────────────
# APIs en el HOST project
# ─────────────────────────────────────────────

module "apis_host" {
  source = "../modules/apis"
  project_id = var.host_project_id
  services = [ 
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudaicompanion.googleapis.com",

   ]
}

# ─────────────────────────────────────────────
# Red (VPC, subnets, NAT, Router)
# ─────────────────────────────────────────────
module "network" {
  source             = "../modules/network"
  project_id         = var.host_project_id
  region             = var.region
  vpc_name           = "vpc-kuik"
  dev_project_number = var.dev_project_number
  depends_on         = [module.apis_host]
 
  subnets = [
    {
      name = "gke"
      cidr = "10.0.0.0/20"
      secondary_ranges = [
        { range_name = "pods",     cidr = "10.20.0.0/16" },
        { range_name = "services", cidr = "10.30.0.0/20" },
      ]
    },
  ]
}

# ─────────────────────────────────────────────
# Firewall
# ─────────────────────────────────────────────
module "firewall" { 
  source = "../modules/firewall"
  project_id = var.host_project_id
  network_id = module.network.network_id
  
}
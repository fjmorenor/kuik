resource "google_compute_network" "main" {
  name = var.vpc_name
  project = var.project_id
  auto_create_subnetworks = false
  
}

resource "google_compute_subnetwork" "main" {
  for_each = {for s in var.subnets : s.name => s}
  name = each.value.name
  project = var.project_id
  region = var.region
  private_ip_google_access = true
  ip_cidr_range = each.value.cidr
  network = google_compute_network.main.id
  dynamic "secondary_ip_range" {
    for_each = coalesce(each.value.secondary_ranges, [])
       
    content {
      range_name = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.cidr
    }
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling = 0.5
    metadata = "INCLUDE_ALL_METADATA"
  }

}


resource "google_compute_router" "main" {
  name = "router-${var.vpc_name}"
  project = var.project_id
  region = var.region
  network = google_compute_network.main.id
  }

resource "google_compute_router_nat" "main" {
  name = "nat-${var.vpc_name}"
  project = var.project_id
  region = var.region
  router = google_compute_router.main.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option = "AUTO_ONLY"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  
}
resource "google_compute_subnetwork_iam_member" "dev_gke" {
  project    = var.project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.main["gke"].name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${var.dev_project_number}@cloudservices.gserviceaccount.com"
}

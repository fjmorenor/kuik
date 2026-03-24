resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
  deletion_protection = false
 
  # Cluster privado: nodos sin IP pública
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # El control plane es accesible desde internet
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
 
  # Usar la red del host project (Shared VPC)
  network    = var.network_id
  subnetwork = var.subnet_names
 
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
 
  # Workload Identity: los pods se autentican como GSA sin JSON keys
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
 
  # Eliminar el node pool default — crearemos los nuestros
  remove_default_node_pool = true
  initial_node_count       = 1
 
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
 
  addons_config {
    http_load_balancing        { disabled = false }
    horizontal_pod_autoscaling { disabled = false }
  }
 
  maintenance_policy {
    daily_maintenance_window { start_time = "03:00" }
  }
 
  lifecycle { ignore_changes = [initial_node_count] }
}
 
# Node pool: sistema
resource "google_container_node_pool" "system" {
  name     = "system"
  cluster  = google_container_cluster.main.id
  location = var.region
  project  = var.project_id
  node_count = 1
 
  node_config {
    machine_type    = "e2-medium"
    service_account = var.nodes_sa_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    tags = [ "web-server", "ssh-allowed" ]
    workload_metadata_config { mode = "GKE_METADATA" }
    labels = { role = "system" }
      taint {
    key    = "components.gke.io/gke-managed-components"
    value  = "true"
    effect = "NO_SCHEDULE"
    
  }
  }
}
 
# Node pool: aplicaciones
resource "google_container_node_pool" "app" {
  name     = "app"
  cluster  = google_container_cluster.main.id
  location = var.region
  project  = var.project_id
 
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
 
  node_config {
    machine_type="e2-medium"
    disk_size_gb = 30
    disk_type = "pd-standard"
    service_account = var.nodes_sa_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    workload_metadata_config { mode = "GKE_METADATA" }
    labels = { role = "app" }
  }
}

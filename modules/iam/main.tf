resource "google_service_account" "gke_nodes" {
  account_id = "sa-gke-nodes"
  display_name = "SA para nodos GKE"
  project = var.project_id
}

resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"

}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Permiso en el host project para usar la red compartida
resource "google_project_iam_member" "gke_network_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# SA de GKE (container-engine-robot) — networkUser en host
resource "google_project_iam_member" "gke_robot_network_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${var.dev_project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# SA de Google APIs (cloudservices) — networkUser en host
resource "google_project_iam_member" "cloudservices_network_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${var.dev_project_number}@cloudservices.gserviceaccount.com"
}

# SA de GKE (container-engine-robot) — hostServiceAgentUser en host
resource "google_project_iam_member" "gke_robot_host_agent" {
  project = var.host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${var.dev_project_number}@container-engine-robot.iam.gserviceaccount.com"
}

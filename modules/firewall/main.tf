resource "google_compute_firewall" "iap_ssh" {
  name = "allow-iap-ssh"
  network = var.network_id
  project = var.project_id
  allow {
    protocol = "tcp"
    ports = [ "22" ]
  }
  
  source_ranges = [ "35.235.240.0/20"]
  target_tags = [ "ssh-allowed" ]
}

resource "google_compute_firewall" "health_check" {
  name = "allow-health-check"       
  network = var.network_id
  project = var.project_id
  allow {
    protocol = "tcp"
    }
  source_ranges = [ "130.211.0.0/22","35.191.0.0/16"]
  target_tags = [ "web-server" ]
  
}

resource "google_compute_firewall" "gke_internal" {
  name = "allow-gke-internal" 
  network = var.network_id
  project = var.project_id
  allow {protocol = "tcp"}
  allow {protocol = "udp"}
  allow {protocol = "icmp"}
  source_ranges = ["10.20.0.0/16"]
}
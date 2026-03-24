output "network_id" {
  value = google_compute_network.main.id
}

output "network_name" {
  value = google_compute_network.main.name
}

output "subnet_ids" {
  value = {for k, v in google_compute_subnetwork.main : k => v.id} 
}

output "subnet_names" {
  value = { for k, v in google_compute_subnetwork.main : k => v.self_link }
  # Devuelve un mapa: nombre_subred => nombre_subred
}

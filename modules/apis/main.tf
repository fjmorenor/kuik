resource "google_project_service" "apis" {
  project = var.project_id
  service = each.value
  for_each = toset(var.services)
  disable_on_destroy = false
}
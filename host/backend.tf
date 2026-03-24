terraform {
  backend "gcs" {
    bucket = "tf-state-host-002"
    prefix = "landing-zone/host"
  }
}

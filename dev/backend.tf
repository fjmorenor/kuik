terraform {
  backend "gcs" {
    bucket = "tf-state-dev-002"
    prefix = "landing-zone/dev"
  }
}
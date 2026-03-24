variable "region" {
    type = string
}

variable "dev_project_id" {
}

variable "services" {
  type    = list(string)
  default = []
}

variable "alert_email" {
    type = string
}

variable "host_project_id" {
    type = string
}

variable "cluster_name" {
  type = string
}

variable "dev_project_number" {
    type = string
}
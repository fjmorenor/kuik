variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "dev_project_number" {
  type = string
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    secondary_ranges = optional(list(object({
      range_name = string
      cidr = string
    })))
  }))
}
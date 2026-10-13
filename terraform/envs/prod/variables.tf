variable "region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}
variable "single_nat_gateway" {
  type    = bool
  default = false
}
variable "instance_types" {
  type    = list(string)
  default = ["m6i.xlarge"]
}
variable "min_nodes" {
  type    = number
  default = 3
}
variable "max_nodes" {
  type    = number
  default = 10
}
variable "spot" {
  type    = bool
  default = false
}
variable "multi_az" {
  type    = bool
  default = true
}
variable "deletion_protection" {
  type    = bool
  default = true
}

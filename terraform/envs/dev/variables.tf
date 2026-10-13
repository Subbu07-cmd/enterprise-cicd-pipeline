variable "region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "instance_types" {
  type    = list(string)
  default = ["t3.large"]
}
variable "min_nodes" {
  type    = number
  default = 1
}
variable "max_nodes" {
  type    = number
  default = 3
}
variable "spot" {
  type    = bool
  default = true
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "deletion_protection" {
  type    = bool
  default = false
}

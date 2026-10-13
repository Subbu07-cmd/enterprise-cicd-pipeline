variable "region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}
variable "min_nodes" {
  type    = number
  default = 2
}
variable "max_nodes" {
  type    = number
  default = 4
}
variable "spot" {
  type    = bool
  default = true
}
variable "multi_az" {
  type    = bool
  default = false
}

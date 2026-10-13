variable "name" { type = string }
variable "cidr" { type = string }
variable "az_count" {
  type    = number
  default = 3
}
variable "single_nat_gateway" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

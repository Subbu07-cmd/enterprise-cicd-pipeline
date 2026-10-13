variable "name" { type = string }
variable "cidr" { type = string }
variable "azs" {
  description = "Availability Zones to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
variable "single_nat_gateway" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

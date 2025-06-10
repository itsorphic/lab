variable "vpc_cidr_block" {
    default = "10.0.0.0/16"
    description = "CIDR Block for the main VPC."
    type = string
}

variable "web_subnet" {
    default = "10.0.10.0/24"
    description = "Subnet for the Web Application"
    type = string
}

variable "subnet_zone" {
    description = "Availability Zone for the application"
    type = string
}

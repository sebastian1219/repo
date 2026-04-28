data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "db_master" {
  length  = 24
  special = false
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  vpc_cidr = "10.${var.vpc_octet}.0.0/16"

  public_subnets = [
    cidrsubnet(local.vpc_cidr, 8, 1),
    cidrsubnet(local.vpc_cidr, 8, 2),
  ]
  private_subnets = [
    cidrsubnet(local.vpc_cidr, 8, 11),
    cidrsubnet(local.vpc_cidr, 8, 12),
  ]

  forward_ports = concat(
    [for p in range(var.alb_nodeport_start, var.alb_nodeport_end + 1) : p],
    [var.grafana_nodeport]
  )
}

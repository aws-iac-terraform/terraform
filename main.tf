terraform {
  required_version = "1.1.7"

  required_providers {
    aws = "~> 4.9"
  }

  backend "remote" {
    organization = "aws-iac-terraform"
    workspaces {
      name = "aws-iac-terraform-workspace"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      env = "aws_iac_terraform"
    }
  }
}

data "aws_caller_identity" "self" {}

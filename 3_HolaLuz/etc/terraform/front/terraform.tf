terraform {
  required_version = "~> 1.0"

  backend "s3" {
    bucket               = "holaluz-terraform"
    key                  = "terraform.tfstate"
    dynamodb_table       = "terraform-state-lock"
    region               = "eu-west-1"
    workspace_key_prefix = "holaluz/st-vgpastor-test3/frontal"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.9"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "cs3-lambda"   # jouw bucketnaam
    key            = "cs3/infra/terraform.tfstate" # willekeurig pad in die bucket
    region         = "eu-central-1"                # zelfde regio als bucket
    dynamodb_table = "cs3-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

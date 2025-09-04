# Backend Configuration for sec-llm-infra
# Separate backend configuration following best practices

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.11"
    }
  }

  backend "s3" {
    bucket       = "sec-llm-infra-terraform-state"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

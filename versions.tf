
terraform {
  required_version = ">= 0.14"
  #required_version = ">= 1.0"  to check compatibility with newer terraform release
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

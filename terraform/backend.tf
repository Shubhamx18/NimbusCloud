terraform {
  backend "s3" {
    bucket         = "nimbuscloud-terraform-state"
    key            = "nimbuscloud/prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "nimbuscloud-terraform-lock"
    encrypt        = true
  }
}
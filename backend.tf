##this will not be used till the end when everything is working fine locally

/*
terraform {
  backend "s3" {
    bucket         = "reverse-proxy-terraform-state-mohamed" # must be globally unique
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
*/
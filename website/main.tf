provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.27"
}

terraform {
  backend "s3" {
    bucket         = "me.fabiooliveira.website.tfstate"
    key            = "website/terraform.tfstate"
    dynamodb_table = "fabiooliveira-website-tfstate-lock"
    region         = "eu-central-1"
  }
}

module "website_with_cname" {
  source         = "git::https://github.com/cloudposse/terraform-aws-s3-website.git?ref=master"
  namespace      = "website"
  stage          = "prod"
  name           = "fabiooliveira"
  hostname       = "www.fabiooliveira.me"
  parent_zone_id = "Z2T01GNL4E6WCM"
}

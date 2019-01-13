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


module "cdn" {
  source           = "git::https://github.com/cloudposse/terraform-aws-cloudfront-s3-cdn.git?ref=master"
  namespace        = "website"
  stage            = "prod"
  name             = "fabiooliveira"
  aliases          = ["www.fabiooliveira.me","fabiooliveira.me"]
  parent_zone_id   = "Z2T01GNL4E6WCM"
}

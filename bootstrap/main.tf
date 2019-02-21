provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.27"
}

provider "local" {
  version = "~> 1.1"
}

provider "template" {
  version = "~> 1.0"
}

module "website-tfstate" {
  source         = "git::https://github.com/confluentinc/terraform-state"
  env            = "prod"
  s3_bucket      = "me.fabiooliveira.website.tfstate"
  s3_bucket_name = "fabiooliveira.me website Terraform state"
  dynamodb_table = "fabiooliveira-website-tfstate-lock"
}

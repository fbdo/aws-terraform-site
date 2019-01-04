provider "aws" {
  region = "eu-central-1"
  profile = "fabiooliveira_website"
  version = "~> 1.27"
}

provider "random" {
    version = "= 1.3.1"
}

resource "random_string" "website-s3-state" {
    lenght = 8
    special = false
    upper = false
}

provider "local" {
    version = "~> 1.1"
}

provider "template" {
    version = "~> 1.0"
}

module "website-tfstate" {
  source = "git::https://github.com/confluentinc/terraform-state"
  env = "prod"
  s3_bucket = "me.fabiooliveira.website.tfstate.${random_string.website.result}"
  s3_bucket_name = "fabiooliveira.me website Terraform state"
  dynamodb_table = "fabiooliveira-website-tfstate-lock"
}
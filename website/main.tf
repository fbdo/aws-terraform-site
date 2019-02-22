provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.27"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "me.fabiooliveira.website.tfstate"
    key            = "website/terraform.tfstate"
    dynamodb_table = "fabiooliveira-website-tfstate-lock"
    region         = "eu-central-1"
  }
}

data "archive_file" "rewrite" {
  type        = "zip"
  output_path = "${path.module}/build/rewrite.zip"
  source_file = "${path.module}/files/lambda_index_url_rewrite.js"
}

resource "aws_lambda_function" "rewrite" {
  provider         = "aws.use1"
  function_name    = "lambda_index_url_rewrite"
  filename         = "${data.archive_file.rewrite.output_path}"
  source_code_hash = "${data.archive_file.rewrite.output_base64sha256}"
  role             = "${aws_iam_role.main.arn}"
  runtime          = "nodejs6.10"
  handler          = "lambda_index_url_rewrite.handler"
  memory_size      = 128
  timeout          = 3
  publish          = true
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "main" {
  name_prefix        = "fabiooliveira.me_rewrite"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "cdn" {
  source                 = "git::https://github.com/cloudposse/terraform-aws-cloudfront-s3-cdn.git?ref=master"
  namespace              = "website"
  stage                  = "prod"
  name                   = "fabiooliveira"
  aliases                = ["www.fabiooliveira.me", "fabiooliveira.me"]
  parent_zone_id         = "Z2T01GNL4E6WCM"
  compress               = true
  viewer_protocol_policy = "redirect-to-https"
  cors_allowed_origins   = ["www.fabiooliveira.me", "fabiooliveira.me"]

  lambda_function_association = [{
    lambda_arn = "arn:aws:lambda:us-east-1:144289250204:function:lambda_index_url_rewrite:3"
    event_type = "origin-request"
  }]
}

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

data "archive_file" "rewrite" {
  type = "zip"
  output_path = "${path.module}/.zip/rewrite.zip"
  source {
    filename = "lambda_index_url_rewrite.js"
    content = "${file("files/lambda_index_url_rewrite.js")}"
  }
}

resource "aws_lambda_function" "rewrite" {
  function_name = "lambda_index_url_rewrite"
  filename = "${data.archive_file.rewrite.output_path}"
  source_code_hash = "${data.archive_file.rewrite.output_base64sha256}"
  role = "${aws_iam_role.main.arn}"
  runtime = "nodejs6.10"
  handler = "index.handler"
  memory_size = 128
  timeout = 3
  publish = true
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}
resource "aws_iam_role" "main" {
  name_prefix = "${var.app_name}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy_attachment" "basic" {
  role = "${aws_iam_role.main.name}"
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
  viewer_protocol_policy = "allow-all"
  lambda_function_association = ["${aws_lambda_function.rewrite.qualified_arn}"]
}

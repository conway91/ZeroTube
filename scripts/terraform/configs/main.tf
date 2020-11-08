terraform {
  backend "s3" {
    bucket = "conway-terraform-states"
    key    = "zerotube-configs"
    region = "eu-west-1"
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_ssm_parameter" "YOUTUBE_API_TOKEN" {
  name  = "/zerotube/YOUTUBE_API_TOKEN"
  type  = "SecureString"
  value = var.youtube_api_token

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_ssm_parameter" "DYNAMODB_AWS_ACCESS_KEY" {
  name  = "/zerotube/DYNAMODB_AWS_ACCESS_KEY"
  type  = "SecureString"
  value = var.dynamodb_aws_access_key

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_ssm_parameter" "DYNAMODB_AWS_SECRET_ACCESS_KEY" {
  name  = "/zerotube/DYNAMODB_AWS_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = var.dynamodb_aws_secret_access_key

  tags = {
    project = "ZeroTube"
  }
}

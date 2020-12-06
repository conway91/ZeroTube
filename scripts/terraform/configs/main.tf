terraform {
  backend "s3" {
    bucket  = "conway-terraform-states"
    key     = "zerotube-configs"
    region  = "eu-west-1"
    profile = "default"
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

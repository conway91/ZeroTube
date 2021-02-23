terraform {
  backend "s3" {
    bucket  = "conway-terraform-states"
    key     = "zerotube"
    region  = "eu-west-1"
    profile = "default"
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

data "aws_ssm_parameter" "YOUTUBE_API_TOKEN" {
  name = "/zerotube/YOUTUBE_API_TOKEN"
}

resource "aws_s3_bucket" "zerotube-site-logs" {
  bucket = "${var.domain_name}-site-logs"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "zerotube-site" {
  bucket = "www.${var.domain_name}"
  acl = "public-read"

  logging {
    target_bucket = aws_s3_bucket.zerotube-site-logs.bucket
    target_prefix = "www.${var.domain_name}/"
  }

  website {
    index_document = "index.html"
  }
}

resource "aws_dynamodb_table" "zerotube_db" {
  name           = "ZeroTube"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_iam_role" "lambda_function_iam_role" {
  name = "populate-youtube-links-lambda-function-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_iam_policy" "lambda_function_iam_role_policy" {
  name = "zerotube-lambda-function-iam-role-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowLogging",
            "Action": [
                "logs:CreateLogGroup",
                 "logs:CreateLogStream",
                 "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "AllowDynamo",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.lambda_function_iam_role.name
  policy_arn = aws_iam_policy.lambda_function_iam_role_policy.arn
}

resource "aws_lambda_function" "create_youtube_links_lambda_function" {
  function_name = "zerotube-create-youtube-links-lambda-function_${var.populate_youtube_links_version}"
  s3_bucket     = "conway-build-artifacts"
  s3_key        = "zerotube/CreateYouTubeLinksFunction_${var.populate_youtube_links_version}.zip"
  role          = aws_iam_role.lambda_function_iam_role.arn
  handler       = "artifacts/CreateYouTubeLinksFunction/main"
  runtime       = "go1.x"
  timeout       = 120

  environment {
    variables = {
      SEARCH_TERMS       = var.youtube_search_terms
      MAXIMUM_VIEW_COUNT = var.youtube_max_view_count
      YOUTUBE_API_TOKEN  = data.aws_ssm_parameter.YOUTUBE_API_TOKEN.value
      DYNAMO_TABLE_NAME  = aws_dynamodb_table.zerotube_db.name
    }
  }

  tags = {
    project = "ZeroTube"
  }
}

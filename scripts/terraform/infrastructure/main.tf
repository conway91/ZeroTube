terraform {
  backend "s3" {
    bucket = "conway-terraform-states"
    key    = "zerotube"
    region = "eu-west-1"
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

data "aws_ssm_parameter" "YOUTUBE_API_TOKEN" {
  name = "/zerotube/YOUTUBE_API_TOKEN"
}

data "aws_ssm_parameter" "DYNAMODB_AWS_ACCESS_KEY" {
  name = "/zerotube/DYNAMODB_AWS_ACCESS_KEY"
}

data "aws_ssm_parameter" "DYNAMODB_AWS_SECRET_ACCESS_KEY" {
  name = "/zerotube/DYNAMODB_AWS_SECRET_ACCESS_KEY"
}

resource "aws_s3_bucket" "zerotube-site-logs" {
  bucket = "${var.domain_name}-site-logs"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "zerotube-site" {
  bucket = "www.${var.domain_name}"

  logging {
    target_bucket = aws_s3_bucket.zerotube-site-logs.bucket
    target_prefix = "www.${var.domain_name}/"
  }

  website {
    index_document = "index.html"
  }
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name         = "ZeroTubeLinks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

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
  name = "populate-youtube-links-lambda-function-iam-role-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListAndDescribe",
            "Effect": "Allow",
            "Action": [
                "dynamodb:List*",
                "dynamodb:DescribeReservedCapacity*",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeTimeToLive"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SpecificTable",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWrite*",
                "dynamodb:Delete*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/ZeroTubeLinks"
        },
        {
            "Sid": "AllowLogging",
            "Action": [
                "logs:CreateLogGroup",
                 "logs:CreateLogStream",
                 "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.lambda_function_iam_role.name
  policy_arn = aws_iam_policy.lambda_function_iam_role_policy.arn
}

resource "aws_lambda_function" "populate_youtube_links_lambda_function" {
  function_name = "populate-youtube-links-lambda-function"
  s3_bucket     = "conway-build-artifacts"
  s3_key        = "zerotube/PopulateYouTubeLinksFunction_${var.populate_youtube_links_version}.zip"
  role          = aws_iam_role.lambda_function_iam_role.arn
  handler       = "ZeroTube.Lambda.PopulateYouTubeLinksFunction::ZeroTube.Lambda.PopulateYouTubeLinksFunction.Function::FunctionHandler"
  runtime       = "dotnetcore3.1"
  timeout       = 120

  environment {
    variables = {
      SEARCH_TERMS                   = var.youtube_search_terms
      MAXIMUM_VIEW_COUNT             = var.youtube_max_view_count
      YOUTUBE_API_TOKEN              = data.aws_ssm_parameter.YOUTUBE_API_TOKEN.value
      DYNAMODB_AWS_ACCESS_KEY        = data.aws_ssm_parameter.DYNAMODB_AWS_ACCESS_KEY.value
      DYNAMODB_AWS_SECRET_ACCESS_KEY = data.aws_ssm_parameter.DYNAMODB_AWS_SECRET_ACCESS_KEY.value
    }
  }

  tags = {
    project = "ZeroTube"
  }
}

terraform {
  backend "s3" {
    bucket = "conway-build-artifacts"
    key    = "zerotube"
    region = "eu-west-1"
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
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
                "dynamodb:CreateTable",
                "dynamodb:Delete*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/ZeroTubeLinks"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.lambda_function_iam_role.name
  policy_arn = aws_iam_policy.lambda_function_iam_role_policy.arn
}

variable "artifact_bucket_key" {
  type        = string
  description = "Bucket folder where the zipped artifact exists"
  default     = "zerotube/PopulateYouTubeLinksFunction_latest.zip"
}

resource "aws_lambda_function" "populate_youtube_links_lambda_function" {
  function_name = "populate-youtube-links-lambda-function"
  s3_bucket     = var.artifact_bucket_name
  s3_key        = "zerotube/PopulateYouTubeLinksFunction_${var.populate_youtube_links_version}.zip"
  role          = aws_iam_role.lambda_function_iam_role.arn
  handler       = "ZeroTube.Lambda.PopulateYouTubeLinksFunction::ZeroTube.Lambda.PopulateYouTubeLinksFunction.Function::FunctionHandler"
  runtime       = "dotnetcore3.1"

  environment {
    variables = {
      SEARCH_TERMS               = var.youtube_search_terms
      MAXIMUM_VIEW_COUNT         = var.youtube_max_view_count
      YOUTUBE_API_TOKEN          = var.youtube_api_token
      DYNAMODB_AWS_ACCESS_KEY    = var.aws_access_key
      DYNAMODB_SECRET_ACCESS_KEY = var.aws_secret_key
    }
  }

  tags = {
    project = "ZeroTube"
  }
}

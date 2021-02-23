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
  function_name = "zerotube-create-youtube-links-lambda-function_${var.lambda_version}"
  s3_bucket     = "conway-build-artifacts"
  s3_key        = "zerotube/CreateYouTubeLinksFunction_${var.lambda_version}.zip"
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

resource "aws_lambda_function" "get_random_youtube_link_lambda_function" {
  function_name = "zerotube-get-random-youtube-link-lambda-function_${var.lambda_version}"
  s3_bucket     = "conway-build-artifacts"
  s3_key        = "zerotube/GetRandomYouTubeLinkFunction_${var.lambda_version}.zip"
  role          = aws_iam_role.lambda_function_iam_role.arn
  handler       = "artifacts/GetRandomYouTubeLinkFunction/main"
  runtime       = "go1.x"
  timeout       = 120

  environment {
    variables = {
      DYNAMO_TABLE_NAME  = aws_dynamodb_table.zerotube_db.name
    }
  }

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_api_gateway_rest_api" "zerotube_agw" {
  name        = "zerotube-api"
  description = "API for ZeroTube website"

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_api_gateway_resource" "random_agw_resource" {
  rest_api_id = aws_api_gateway_rest_api.zerotube_agw.id
  parent_id   = aws_api_gateway_rest_api.zerotube_agw.root_resource_id
  path_part   = "random"
}

resource "aws_api_gateway_method" "random_agw_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  resource_id   = aws_api_gateway_resource.random_agw_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "random_agw_get_method_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.zerotube_agw.id
  resource_id = aws_api_gateway_method.random_agw_get_method.resource_id
  http_method = aws_api_gateway_method.random_agw_get_method.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_random_youtube_link_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "agw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.zerotube_agw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.random_agw_resource.id,
      aws_api_gateway_method.random_agw_get_method.id,
      aws_api_gateway_integration.random_agw_get_method_lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "agw_stage" {
  deployment_id = aws_api_gateway_deployment.agw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "agw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_random_youtube_link_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.zerotube_agw.execution_arn}/*/*"
}
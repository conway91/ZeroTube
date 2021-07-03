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

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_s3_bucket_policy" "zerotube-site-policy" {
  bucket = aws_s3_bucket.zerotube-site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource = "arn:aws:s3:::www.${var.domain_name}/*"
      },
    ]
  })
}

resource "aws_s3_bucket" "zerotube-site-subdomain" {
  bucket = var.domain_name
  acl = "public-read"

  website {
    redirect_all_requests_to = "www.${var.domain_name}"
  }

  tags = {
    project = "ZeroTube"
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
                "dynamodb:PutItem",
                "dynamodb:Scan"
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
  s3_key        = "zerotube/CreateYouTubeLinksFunction/CreateYouTubeLinksFunction_${var.lambda_version}.zip"
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

resource "aws_cloudwatch_log_group" "create_youtube_links_lambda_function_log_group" {
  name = "/aws/lambda/${aws_lambda_function.create_youtube_links_lambda_function.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "get_random_youtube_link_lambda_function" {
  function_name = "zerotube-get-random-youtube-link-lambda-function_${var.lambda_version}"
  s3_bucket     = "conway-build-artifacts"
  s3_key        = "zerotube/GetRandomYouTubeLinkFunction/GetRandomYouTubeLinkFunction_${var.lambda_version}.zip"
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

resource "aws_cloudwatch_log_group" "get_random_youtube_link_lambda_function_log_group" {
  name = "/aws/lambda/${aws_lambda_function.get_random_youtube_link_lambda_function.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "cleanup_youtube_link_lambda_function" {
  function_name = "zerotube-cleanup-youtube-links-lambda-function_${var.lambda_version}"
  s3_bucket     = "conway-build-artifacts"
  s3_key        = "zerotube/CleanupYouTubeLinksFunction/CleanupYouTubeLinksFunction_${var.lambda_version}.zip"
  role          = aws_iam_role.lambda_function_iam_role.arn
  handler       = "artifacts/CleanupYouTubeLinksFunction/main"
  runtime       = "go1.x"
  timeout       = 120

  environment {
    variables = {
      DYNAMO_TABLE_NAME  = aws_dynamodb_table.zerotube_db.name
      MAXIMUM_VIEW_COUNT = var.youtube_max_view_count
      YOUTUBE_API_TOKEN  = data.aws_ssm_parameter.YOUTUBE_API_TOKEN.value
    }
  }

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_cloudwatch_log_group" "cleanup_youtube_links_lambda_function_log_group" {
  name = "/aws/lambda/${aws_lambda_function.cleanup_youtube_link_lambda_function.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "zerotube_create_youtube_links_lambda_function_event_rule" {
  name                = "zerotube-create-youtube-links-lambda-function-event-rule"
  description         = "Triggers the lambda every 3 hours"
  schedule_expression = "rate(3 hours)"
}

resource "aws_cloudwatch_event_target" "zerotube_create_youtube_links_lambda_function_event_target" {
  rule      = aws_cloudwatch_event_rule.zerotube_create_youtube_links_lambda_function_event_rule.name
  target_id = "lambda"
  arn       = aws_lambda_function.create_youtube_links_lambda_function.arn
}

resource "aws_lambda_permission" "zerotube_create_youtube_links_lambda_function_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_youtube_links_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.zerotube_create_youtube_links_lambda_function_event_rule.arn
}

resource "aws_api_gateway_account" "agw_account" {
  cloudwatch_role_arn = aws_iam_role.agw_global_cloudwatch_role.arn
}

resource "aws_iam_role" "agw_global_cloudwatch_role" {
  name = "api-gateway-cloudwatch-global-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "agw_global_cloudwatch_role_policy" {
  name = "api-gateway-cloudwatch-global-iam-role-policy"
  role = aws_iam_role.agw_global_cloudwatch_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
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

resource "aws_api_gateway_method" "random_agw_options_method" {
  rest_api_id   =  aws_api_gateway_rest_api.zerotube_agw.id
  resource_id   = aws_api_gateway_resource.random_agw_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "random_agw_options_200" {
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  resource_id   = aws_api_gateway_resource.random_agw_resource.id
  http_method   = aws_api_gateway_method.random_agw_options_method.http_method
  status_code   = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }

  depends_on = [aws_api_gateway_method.random_agw_options_method]
}

resource "aws_api_gateway_integration" "random_agw_options_integration" {
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  resource_id   = aws_api_gateway_resource.random_agw_resource.id
  http_method   = aws_api_gateway_method.random_agw_options_method.http_method
  type          = "MOCK"

  depends_on = [aws_api_gateway_method.random_agw_options_method]
}

resource "aws_api_gateway_integration_response" "random_agw_options_integration_response" {
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  resource_id   = aws_api_gateway_resource.random_agw_resource.id
  http_method   = aws_api_gateway_method.random_agw_options_method.http_method
  status_code   = aws_api_gateway_method_response.random_agw_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin" = "'http://www.zerotube.org.s3-website-eu-west-1.amazonaws.com/'"
  }

  depends_on = [aws_api_gateway_method_response.random_agw_options_200]
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

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_random_youtube_link_lambda_function.invoke_arn
}

resource "aws_api_gateway_method_response" "random_agw_get_200" {
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  resource_id   = aws_api_gateway_resource.random_agw_resource.id
  http_method   = aws_api_gateway_method.random_agw_get_method.http_method
  status_code   = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = false
  }

  depends_on = [aws_api_gateway_method.random_agw_options_method]
}

resource "aws_api_gateway_deployment" "agw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.zerotube_agw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.random_agw_resource.id,
      aws_api_gateway_method.random_agw_get_method.id,
      aws_api_gateway_integration.random_agw_get_method_lambda_integration.id,
      aws_api_gateway_method.random_agw_options_method.id,
      aws_api_gateway_integration.random_agw_options_integration.id,
      aws_lambda_function.get_random_youtube_link_lambda_function.arn
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "agw_stage" {
  depends_on = [aws_cloudwatch_log_group.agw_log_group]

  deployment_id = aws_api_gateway_deployment.agw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.zerotube_agw.id
  stage_name    = "zerotube"

  tags = {
    project = "ZeroTube"
  }
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.zerotube_agw.id
  stage_name  = aws_api_gateway_stage.agw_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_cloudwatch_log_group" "agw_log_group" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.zerotube_agw.id}/zerotube"
  retention_in_days = 7
}

resource "aws_lambda_permission" "agw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_random_youtube_link_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.zerotube_agw.execution_arn}/*/*"
}

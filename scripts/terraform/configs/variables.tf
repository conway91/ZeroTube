variable "aws_region" {
  type        = string
  description = "Region of the Terraform state and lambda"
  default     = "eu-west-1"
}

variable "youtube_api_token" {
  type        = string
  description = "Youtube API token for connecting to the youtube service"
}

variable "dynamodb_aws_access_key" {
  type        = string
  description = "AWS access key for providing dynamo access to lambda"
}

variable "dynamodb_aws_secret_access_key" {
  type        = string
  description = "AWS secret access key for providing dynamo access to lambda"
}

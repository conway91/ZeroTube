variable "aws_region" {
  type        = string
  description = "Region of the Terraform state and lambda"
  default     = "eu-west-1"
}

variable "youtube_api_token" {
  type        = string
  description = "Youtube API token for connecting to the youtube service"
}

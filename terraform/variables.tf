variable "region" {
  type        = string
  description = "Region of the Terraform state and lambda"
}

variable "youtube_api_token" {
  type        = string
  description = "Youtube API token for connecting to the youtube service"
}

variable "domain_name" {
  type        = string
  description = "Domain name for static bucket site"
}

variable "lambda_version" {
  type        = string
  description = "Lambda version to deploy"
}

variable "youtube_search_terms" {
  type        = string
  description = "Comma separated string of the terms to search (max recommended is 5 to not hit api quota)"
}

variable "youtube_max_view_count" {
  type        = string
  description = "Maximum view count of videos to include in final result"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "The ID of the cloud distribution created via the AWS console"
}

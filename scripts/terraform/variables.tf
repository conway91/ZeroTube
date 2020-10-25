variable "aws_region" {
  type        = string
  description = "Region of the Terraform state and lambda"
  default     = "eu-west-1"
}

variable "artifact_bucket_name" {
  type        = string
  description = "Bucket where the zipped artifact exists"
}

variable "populate_youtube_links_version" {
  type        = string
  description = "Lambda version to deploy for the PopulateYouTubeLinksFunction"
  default     = "latest"
}

variable "youtube_search_terms" {
  type        = string
  description = "Comma separated string of the terms to search (max recommended is 5 to not hit api quota)"
  default     = "webm,mpeg,mkv,avi,flv"
}

variable "youtube_max_view_count" {
  type        = string
  description = "Maximum view count of videos to include in final result"
  default     = "50"
}

variable "youtube_api_token" {
  type        = string
  description = "Api token for accessing the YouTube api"
}

variable "aws_access_key" {
  type        = string
  description = "AWS key for the lambda to access Dynamo"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret for the lambda to access Dynamo"
}

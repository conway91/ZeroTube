variable "aws_region" {
  type        = string
  description = "Region of the Terraform state and lambda"
  default     = "eu-west-1"
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
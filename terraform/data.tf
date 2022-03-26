// CloudFront resources are made and managed manually

data "aws_cloudfront_distribution" "cdn" {
  id = var.cloudfront_distribution_id
}

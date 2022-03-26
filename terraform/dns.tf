resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = {
    project = "zerotube"
  }
}

resource "aws_route53_record" "base_record" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = data.aws_cloudfront_distribution.cdn.domain_name
    zone_id                = data.aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "wwww_record" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_cloudfront_distribution.cdn.domain_name
    zone_id                = data.aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
